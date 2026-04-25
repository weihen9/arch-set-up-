# arch-set-up-
plug and play set up for my arch set up

# scripts to run
git clone <your-github-repo-url> ~/arch-setup
cd ~/arch-setup
chmod +x install.sh scripts/*.sh dotfiles/hypr/scripts/*.sh dotfiles/waybar/scripts/*.sh

./install.sh full
./scripts/restore-dotfiles.sh
./scripts/install-aur.sh
./scripts/sync-elifouts-waybar.sh
./scripts/sync-elifouts-wallpapers.sh
./scripts/enable-services.sh
