# UI motion — 2026-10-03

Scope: shared UIKit buttons, Navigation windows/menu drawer and ToolHotbar cards. Existing art is reused;
no new image assets or gameplay/server intents were needed. Studio place 93479990217075, mock profiles.

## Behavior

- Buttons ease to 1.025 scale on mouse hover/gamepad focus and 0.96 while pressed, then spring back.
  Touch presses use InputBegan/InputEnded. Existing Activated callbacks remain unchanged.
- Navigation panels/menu drawer open from a 0.94 multiplier to 1 over 0.24s. Responsive layout owns
  the base scale; animation multiplies it without changing saved desktop/phone geometry. Closing is immediate.
- Hotbar cards enter in 45ms steps, rebound on selection and show a cyan outline pulse lasting 0.32s.
  Hover/press/selection share one state; replacing a tween cancels its predecessor. Removal cancels pending
  intros/tweens before disconnecting the vendor handler. Bottom inset is 12px for effect clearance.
- Motion durations become zero and equip pulses are skipped when Roblox Reduce Motion is enabled
  ([GuiService reference](https://create.roblox.com/docs/reference/engine/classes/GuiService)).

## Proof

- Native Play in landscape device simulator, viewport 749×361, inset 58. Native input required
  +62.5/+20.5 safe-area correction. Actual menu click opened the drawer and hid ToolHotbar.
- Held Inventory button: ButtonMotion.Scale=0.96. Release opened Inventory; entrance samples moved
  through 0.9835 → 0.9991 → 1, with scale returning to the responsive LayoutScale.
- Actual watering-can selection: scale 0.9348 → 1.0728 → 1.0894 → 1.08;
  pulse transparency 0.464 → 0.759 → 0.911 → 0.988 → 1. Selection/equip behavior preserved.
- Six rapid Inventory open/close cycles: final factor=1, rendered scale equals LayoutScale, panel closes,
  hotbar restores, intro settles. Eight local clone/add/remove cycles: exactly two remaining slots/two rings.
  Synthetic clones were removed; profile data was not changed.
- Existing UIAudit: HUD plus all eleven window/menu targets OVER/OFF/SMALL=0 at 749×361.
  Inspected menu and hotbar screenshots. Final effect clearance change reduces pulse expansion and adds
  4px bottom inset; compile passed again, final console has no runtime errors.
- All five changed sources match Studio via byte checksum. luau-compile and git diff --check passed.

Not verified: real touch device/gamepad, desktop hover in this run, Thai motion screenshots,
or the actual Reduce Motion settings toggle. Reduced Motion was false in the simulator.
No Publish. No test scripts or synthetic tools remain.
