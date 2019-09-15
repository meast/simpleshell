<?php

/**
 * shiro SimpleHash in PHP
 * Hashes the specified byte array using the given {@code salt} for the specified number of iterations.
 *
 * @param algo            Name of selected hashing algorithm (e.g. "md5", "sha256", "haval160,4", etc..)  
 * @param password        the string to hash
 * @param salt            the salt to use for the initial hash
 * @param hash_iterations the number of times the the {@code bytes} will be hashed (for attack resiliency).
 * @return the hashed string.
 */
function simple_hash($algo = 'md5', $password = '', $salt = '', $hash_iterations = 2) {
    $res = '';
    $pass = $salt . $password;
    $encoded = hash($algo, $pass, true);
    $iteration = $hash_iterations - 1;
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
