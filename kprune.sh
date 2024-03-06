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

if ! command -v jq &> /dev/null; then
  echo "jq not found"
  read -p "Do you want to install jq? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing gum..."
    brew install jq
  else
    echo "Skipping jq installation."
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

POD_NR=$(kubectl get pods --field-selector=status.phase==Succeeded,status.phase==Failed -o json | jq -j '.items | length')
CURRENT_NS=$(kubectl config view --minify --output 'jsonpath={..namespace}')

if [[ $POD_NR -eq 0 ]]; then
    gum style  \
      --foreground 292 --border-foreground 292 --border normal \
     "No terminated pods found in namespace $(gum style --foreground 450 "$CURRENT_NS")."
  exit 0
fi

gum style  \
      --foreground 292 --border-foreground 292 --border normal \
      "Pruning $POD_NR Suceeded/Failed pods in namespace $(gum style --bold --foreground 450 "$CURRENT_NS")" && \
gum confirm \
  --selected.foreground="292" \
  --unselected.foreground="292" \
  --prompt.foreground="292" \
  --default=false "Proceed?" && \
  kubectl delete pods \
  --field-selector=status.phase==Succeeded \
  --field-selector=status.phase==Failed && \
  echo "Finished pruning $POD_NR pods"

