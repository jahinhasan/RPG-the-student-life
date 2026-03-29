#!/usr/bin/env bash
set -euo pipefail

# Run this script from the rpg_student_life repository root.
# It clones related repositories as siblings of this repository.

if [[ ! -f "pubspec.yaml" ]]; then
  echo "Please run this script from the rpg_student_life repo root."
  exit 1
fi

if [[ ! -d "../RpgTheStudentLifeFigmaUI/.git" ]]; then
  git clone https://github.com/jahinhasan/RpgTheStudentLifeFigmaUI.git ../RpgTheStudentLifeFigmaUI
else
  echo "RpgTheStudentLifeFigmaUI already exists, skipping clone."
fi

if [[ ! -d "../com.unity.multiplayer.samples.coop/.git" ]]; then
  git clone https://github.com/Unity-Technologies/com.unity.multiplayer.samples.coop.git ../com.unity.multiplayer.samples.coop
else
  echo "com.unity.multiplayer.samples.coop already exists, skipping clone."
fi

echo "Workspace setup complete."
