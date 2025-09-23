<?php
if ($_GET['d'] === date('d')) {
    phpinfo();
} else {
    echo date('d');
}
