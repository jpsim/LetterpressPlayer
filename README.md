# Letterpress Player

Solves Letterpress games via OCR and colour categorization. Work in progress.

Disclaimer: This code is *nasty ugly*, but functional.

# Usage

Take a screenshot of a Letterpress game then launch this app immediately. Wait a few seconds and you'll see the 100 top scoring words possible.

# Goals

Right now, this is more of a "cheating" app, but the end goal is to have a fully automated Letterpress player. Items in the To Do List will address that… eventually.

# To Do List

1. Refactor: this code was written in a few hours and its sense of style is frightening.
2. Determine most valuable word by taking into account box colours. These are already being extracted, just not used.
3. Build a physical iOS testing machine to automate playing.

# Known Issues

My poor-man's "OCR" doesn't like Q's and O's. I could supplement the algorithm with diagonal checksums as well as the existing 9 sums.

# Disclaimer

This was built for research purposes only. I am not responsible for misuse of Atebit's Letterpress game. Use at your own risk, preferably with people who know you're cheating/researching.