#!/bin/bash

echo "========================================"
echo "Pushing to GitHub Repository: Academix"
echo "========================================"
echo ""

echo "Checking git status..."
git status
echo ""

echo "Pushing to academix repository..."
git push academix main
echo ""

echo "Done!"
