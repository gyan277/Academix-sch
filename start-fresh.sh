#!/bin/bash

echo "============================================"
echo "Starting Fresh Git Repository"
echo "============================================"
echo ""
echo "WARNING: This will remove all git history!"
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

echo "Step 1: Removing old .git folder..."
if [ -d ".git" ]; then
    rm -rf .git
    echo "Old .git folder removed!"
else
    echo "No .git folder found."
fi
echo ""

echo "Step 2: Initializing new git repository..."
git init
echo ""

echo "Step 3: Adding all files..."
git add .
echo ""

echo "Step 4: Creating initial commit..."
git commit -m "Initial commit: Complete School Management System"
echo ""

echo "============================================"
echo "Fresh repository created!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Create a new repository on GitHub: https://github.com/new"
echo "2. Run these commands (replace with your repo URL):"
echo ""
echo "   git remote add origin https://github.com/gyan277/Academix.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
