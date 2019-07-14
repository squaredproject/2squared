sudo cp statuscake.timer /etc/systemd/system/
sudo cp statuscake.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable statuscake.timer

