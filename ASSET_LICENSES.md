# Asset and Licensing Audit

## Runtime assets

- Runtime character and projectile PNGs are referenced directly from `sprites/`.
- Runtime dungeon artwork is referenced from `tileset/free-2d-top-down-pixel-dungeon-asset-pack/PNG/`.
- The dungeon pack includes `license.txt`, which points to CraftPix's license terms: <https://craftpix.net/file-licenses/>.
- The current core image is a project placeholder at `assets/placeholder/hell_core_placeholder.png`.

## Source assets intentionally retained

- Aseprite files are retained for editing and excluded from runtime imports with `.gdignore`.
- PSD files are retained for editing and excluded from runtime imports with `.gdignore`.
- Original asset ZIP archives are retained as provenance copies.

## Review required before commercial distribution

- Confirm the character-pack license for the Soldier/Orc and Demon/Blood Monster packs from their original download sources.
- Confirm whether the Digital Disco font may be redistributed with the game.
- Preserve relevant license text and purchase/download records with release materials.

## Unused web artifact audit

The former `tileset/spike-trap-ani_files/` directory contained downloaded HTML/CSS/JavaScript and unrelated preview images. No runtime script or scene referenced it. It was moved to a recoverable temporary archive outside the repository and removed from the project.
