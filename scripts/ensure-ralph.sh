#!/bin/bash
claude plugin list 2>/dev/null | grep -q ralph-wiggum || claude plugin install ralph-wiggum@incubyte-plugins 2>/dev/null
claude plugin list 2>/dev/null | grep -q ralph-wiggum && echo "RALPH_STATUS: INSTALLED" || echo "RALPH_STATUS: NOT_INSTALLED"