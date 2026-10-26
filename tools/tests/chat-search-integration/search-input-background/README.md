# Search input background closing

The input background belongs to ChatSearchView. Its parent was fading in 0.12 seconds while the surrounding native glass had a 0.2-second exit. Restore the full 0.2-second content fade; retain the existing deferred host-height fix and inline merge behavior.

The native scene now renders actual ChatSearchHeader / ChatSearchView controls instead of a Search label. The Unlock label remains controlled text, not a Premium tag. `before.gif` and `after.gif` directly crop equal 2000×1156 native windows. The source-extracted removal block and real native glass are exercised. See verification.json for source references, fresh process IDs, frame intervals, hashes and limitations.

The old header fails the input-background timing check; the corrected suite passes 177 checks. The earlier saved-search-fade text-only scene is historical evidence and does not establish input-background behavior. The actual authenticated client is checked separately; these GIFs are not presented as recordings of that account.
