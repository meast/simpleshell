<?php
function simple_hash($algo = 'md5', $password = '', $salt = '', $hashIterations = 2) {
    $res = '';
    $pass = $salt . $password;
    $encoded = hash($algo, $pass, true);
    $iteration = $hashIterations - 1;
    if($iteration > 0) {
        for($i = 0; $i < $iteration; $i++) {
            $encoded = hash($algo, $encoded, true);
        }
    }
    $tmp = unpack('H*', $encoded);
    if(!empty($tmp) && !empty($tmp[1])) {
        $res = $tmp[1];
    }
    return $res;
}
