#! /bin/bash

set -e

if ! command -v kubectl &> /dev/null; then
  echo "kubectl not found"
  read -p "Do you want to install kubectl? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing kubectl..."
    brew install kubernetes-cli
  else
    echo "Skipping kubectl installation."
    exit 1
  fi
fi

if ! command -v gum &> /dev/null; then
  echo "gum not found"
  read -p "Do you want to install gum? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing gum..."
    brew install gum
  else
    echo "Skipping gum installation."
    exit 1
  fi
fi

if [[ $1 == "-h" || $1 == "--help" ]]; then
  echo "Usage: $(basename $0) [namespace] -- Prune terminated(succeeded/failed) pods in a namespace
  Args:
    namespace: The namespace to be pruned (default: current namespace)
  "
  exit 0
fi

if [[ $1 != "" ]]; then
  CURRENT_NS=$1 
else
  CURRENT_NS=$(kubectl config view --minify --output 'jsonpath={..namespace}')
fi

SUCCEEDED_NR=$(kubectl -n "$CURRENT_NS" get pods --field-selector=status.phase==Succeeded -o name | wc -l | tr -d ' ')
FAILED_NR=$(kubectl -n "$CURRENT_NS" get pods --field-selector=status.phase==Failed -o name | wc -l | tr -d ' ')
POD_NR=$((SUCCEEDED_NR + FAILED_NR))

if [[ $POD_NR -eq 0 ]]; then
    gum style  \
      --foreground 292 --border-foreground 292 --border normal \
     "No terminated pods found in namespace $(gum style --foreground 450 "$CURRENT_NS")."
  exit 0
fi

gum style  \
      --foreground 292 --border-foreground 292 --border normal \
      "Pruning $SUCCEEDED_NR Succeeded and $FAILED_NR Failed pods in namespace $(gum style --bold --foreground 450 "$CURRENT_NS")" 

gum confirm \
  --selected.foreground="292" \
  --unselected.foreground="292" \
  --prompt.foreground="292" \
  --default=false "Proceed?" && \
  if [[ $SUCCEEDED_NR -gt 0 ]]; then
    kubectl -n "$CURRENT_NS" delete pods --field-selector=status.phase==Succeeded
  fi && \
  if [[ $FAILED_NR -gt 0 ]]; then
    kubectl -n "$CURRENT_NS" delete pods --field-selector=status.phase==Failed
  fi && \
  echo "Finished pruning $POD_NR pods"
