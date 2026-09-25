YEAH RIGHT
Version 0.2.4-beta

WHAT IT DOES
------------
When another player sends a message containing "yeah right" or the joined form
"yeahright" in a supported chat type, this addon attempts to reply with exactly:

yeah right

The reply uses the same chat type as the triggering message.

Supported chat types:
- Guild
- Party / Party Leader
- Raid / Raid Leader
- Say
- Yell

Matching is case-insensitive and allows punctuation or extra spaces between
the words. Examples that trigger it include:
- yeah right
- Yeah Right!
- oh, yeah... right, sure
- yeahright
- YeAhRiGhT!

Longer joined words such as "yeahrightly" do not trigger it.

LOOP PREVENTION
---------------
Each chat type has its own 10-second suppression window. Your own original
"yeah right" or "yeahright" also starts that window. This lets multiple addon
users respond once without their responses creating an endless loop.

COMMANDS
--------
/yeahright          Show the command list
/yeahright help     Show the command list
/yeahright on       Enable replies
/yeahright off      Disable replies
/yeahright status   Show current settings
/yeahright debug    Toggle diagnostic messages

INSTALLATION
------------
1. Extract the YeahRight folder into:
   World of Warcraft\_retail_\Interface\AddOns\

   For the WoW Forever beta, use that client's corresponding Interface\AddOns
   directory.

2. The final structure must be:
   Interface\AddOns\YeahRight\YeahRight.toc
   Interface\AddOns\YeahRight\YeahRight.lua
   Interface\AddOns\YeahRight\README.txt

3. At the character-selection screen, open AddOns and enable "Yeah Right".
   If Forever uses a different interface number, also enable
   "Load out-of-date AddOns" until the TOC is updated for the beta.

4. Log in or run /reload.

BETA TESTING
------------
Run /yeahright debug before testing. Diagnostic lines appear only in your own
chat window and are not sent to other players.

Test each supported type with two addon users:
1. Player A sends "Yeah Right!" or "YeahRight!"
2. Player B should answer exactly "yeah right" in the same chat type.
3. Player A and Player B should not continue replying to one another.

Blizzard may protect incoming chat values or reject automatic sends during
encounters, active Mythic+ runs, PvP matches, or other restricted states.
Protected messages are skipped. Failed/blocked messages are never queued for
delivery later.

NOTES
-----
- Say and Yell automatic sends are deliberately skipped outdoors because the
  client requires a hardware event there.
- The included 256 x 256 TGA icon is registered through the addon's TOC file
  for display in clients that support addon-list icons.

VERSION HISTORY
---------------
0.2.4-beta
- Replaced the icon with the selected split YR monogram.
- Increased separation between the letters for clearer small-size display.

0.2.3-beta
- Corrected the TGA pixel orientation so the icon displays upright in WoW.

0.2.2-beta
- Rebuilt the YR icon as native 256 x 256 vector geometry before rasterizing.
- Thickened and simplified the letter shapes for clearer in-game display.
- Removed the noisy outlines and resampling artefacts from the previous icon.

0.2.1-beta
- Added case-insensitive support for the joined trigger "yeahright".
- Kept boundary checks so longer words such as "yeahrightly" do not trigger.

0.2.0-beta
- Added the black-and-white YR addon icon.
- Registered the addon under the Chat category with its custom icon.

0.1.0-beta
- Initial test build.
