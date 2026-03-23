<?php
echo "<h1>azure-vm-lab</h1>";
echo "<p>Hostname : " . gethostname() . "</p>";
echo "<p>IP : " . $_SERVER['SERVER_ADDR'] . "</p>";
echo "<p>Deployed via GitHub Actions + Docker</p>";