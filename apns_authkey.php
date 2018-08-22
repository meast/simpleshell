<?php

$a = new ApnsAuthKey();

$a->test();

class ApnsAuthKey {

    # auth key 的 .p8 私钥文件(必填)
    public $auth_key = '';
    # 团队ID(Team ID, 必填)
    public $team_id = '';
    # 要发送的 APP 包名(Bundle Identifier, 必填)
    public $bundle_id = '';
    # auth key 的 Key ID(必填)
    public $auth_key_id = '';
    # openssl 可执行程序的完整路径(可以使用 brew install openssl)
    public $openssl = '/usr/local/opt/openssl/bin/openssl';
    # 支持 HTTP2.0 的 curl 可执行程序的完整路径(macOS 10.13 自带的 curl 已经可以支持 HTTP2.0)
    public $curl = '/usr/bin/curl';
    # 是否使用开发版推送网关(调试安装/Ad Hoc版可使用, app store/testflight 版本的不能使用开发版推送)
    public $is_dev = TRUE;

    private $_api_url_dev = 'https://api.development.push.apple.com:443';
    private $_api_url_pro = 'https://api.push.apple.com:443';

    public function __construct() {
        if(!empty($_REQUEST['team_id']) && is_string($_REQUEST['team_id'])) {
            $this->team_id = $_REQUEST['team_id'];
        }
        if(!empty($_REQUEST['bundle_id']) && is_string($_REQUEST['bundle_id'])) {
            $this->bundle_id = $_REQUEST['bundle_id'];
        }
        if(!empty($_REQUEST['auth_key_id']) && is_string($_REQUEST['auth_key_id'])) {
            $this->auth_key_id = $_REQUEST['auth_key_id'];
        }
    }

    public function test() {
        $this->is_dev = FALSE;
        $this->bundle_id = '';
        $device_id = '';
        #$this->is_dev = FALSE;
        $arr_msg = array('aps'=>array('alert'=>'', 'sound'=>'', 'badge'=>1));
        #$arr_msg['aps']['alert'] = '您有新消息: api.push.' . date('Y-m-d H:i:s');
        $arr_msg['aps']['alert'] = array();
        $arr_msg['aps']['alert']['title'] = '您有新消息';
        $arr_msg['aps']['alert']['subtitle'] = '您有新消息1';
        $arr_msg['aps']['alert']['body'] = '您有新消息: api.push.' . date('Y-m-d H:i:s');
        
        $res = $this->send_curl($arr_msg, $device_id);

        echo PHP_EOL;
        var_dump($res);
    }


    public function send_to_device($title = '', $body = '', $device_id = '', $arr_extra = array()) {
        if(!empty($device_id)) {
            $arr_msg = array('aps'=>array('alert'=>array(), 'sound'=>'', 'sound'=>'chime', 'badge'=>1));
            
            if(!empty($title)) {
                $title = strtr($title, array('"'=>''));
                $arr_msg['aps']['alert']['title'] = $title;
            }
            if(!empty($body)) {
                $body = strtr($body, array('"'=>' '));
                $arr_msg['aps']['alert']['body'] = $body;
            }
            if(!empty($arr_extra['subtitle'])) {
                $arr_msg['aps']['alert']['subtitle'] = $arr_extra['subtitle'];
            }
            # 国际化相关参数
            if(!empty($arr_extra['action-loc-key'])) {
                $arr_msg['aps']['alert']['action-loc-key'] = $arr_extra['action-loc-key'];
            }
            if(!empty($arr_extra['action-loc-args'])) {
                $arr_msg['aps']['alert']['action-loc-args'] = $arr_extra['action-loc-args'];
            }
            if(!empty($arr_extra['title-loc-key'])) {
                $arr_msg['aps']['alert']['title-loc-key'] = $arr_extra['title-loc-key'];
            }
            if(!empty($arr_extra['title-loc-args'])) {
                $arr_msg['aps']['alert']['title-loc-args'] = $arr_extra['title-loc-args'];
            }
            if(!empty($arr_extra['subtitle-loc-key'])) {
                $arr_msg['aps']['alert']['subtitle-loc-key'] = $arr_extra['subtitle-loc-key'];
            }
            if(!empty($arr_extra['subtitle-loc-args'])) {
                $arr_msg['aps']['alert']['subtitle-loc-args'] = $arr_extra['subtitle-loc-args'];
            }
            if(!empty($arr_extra['loc-key'])) {
                $arr_msg['aps']['alert']['loc-key'] = $arr_extra['loc-key'];
            }
            if(!empty($arr_extra['loc-args'])) {
                $arr_msg['aps']['alert']['loc-args'] = $arr_extra['loc-args'];
            }
            if(!empty($arr_extra['aps'])) {
                $arr_msg['aps'] = array_merge($arr_msg['aps'], $arr_extra['aps']);
            }
            if(!empty($arr_extra)) {
                $arr_msg['extra'] = $arr_extra;
            }
            if(!empty($arr_extra['sound'])) {
                $arr_msg['aps']['sound'] = $arr_extra['sound'];
            }
            if(!empty($arr_extra['badge'])) {
                $arr_msg['aps']['badge'] = $arr_extra['badge'];
            }
            # 使用 shell 发送
            $res = $this->send_curl($arr_msg, $device_id);
            # 使用 扩展 发送
            #$res = $this->send($arr_msg, $device_id);
            return $res;
        }
        return FALSE;
    }

    /**
     * 使用 shell 发送
     */
    public function send_curl($payload = array(), $device_id = '') {
        $url = $this->_api_url_dev;
        if(!$this->is_dev) {
            $url = $this->_api_url_pro;
        }
        $str_payload = json_encode($payload, JSON_UNESCAPED_SLASHES);
        $str_payload = strtr($str_payload, array('"'=>'\\"'));
        $jwt = $this->get_sign();
        #echo $jwt . PHP_EOL;
        # --verbose
        $shell = $this->curl . ' --http2 -s --header "content-type: application/json" --header "authorization: bearer '.$jwt.'" --header "apns-topic: '.$this->bundle_id.'"  --data "'.$str_payload.'"  '.$url.'/3/device/' . $device_id . '';

        #echo $shell . PHP_EOL;

        $arr_output = array();
        $return_var = 0;
        $res_shell = '';
        # TODO: bugfix: web not exec this on mac.
        $res_shell = exec($shell, $arr_output, $return_var);
        #$res_shell = shell_exec($shell);
        return $res_shell;
    }

    /**
     * 使用 PHP 的 curl 扩展发送, 要求 PHP 环境有支持 HTTP2.0的 curl
     */
    public function send($payload = array(), $device_id = '') {
        $str_payload = json_encode($payload, JSON_UNESCAPED_SLASHES);
        $jwt = $this->get_sign();
        $arr_header = array();
        #$arr_header['content-type'] = 'application/json';
        #$arr_header['authorization'] = 'bearer ' . $jwt;
        #$arr_header['apns-topic'] = $this->bundle_id;
        $arr_header[] = 'content-type: application/json';
        $arr_header[] = 'authorization: bearer ' . $jwt;
        $arr_header[] = 'apns-topic: ' . $this->bundle_id;
        $url = $this->_api_url_dev;
        if(!$this->is_dev) {
            $url = $this->_api_url_pro;
        }
        $url .= '/3/device/' . $device_id;
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $arr_header);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $str_payload);
        #curl_setopt($ch, CURLOPT_VERBOSE, TRUE);

        #curl_setopt($ch, CURLOPT_SSLCERT, $pem_file);
        #curl_setopt($ch, CURLOPT_SSLCERTPASSWD, $pem_secret);
        $response = curl_exec($ch);
        $httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        curl_close($ch);
        if($httpcode == 200) {
            return TRUE;
        }
        return $response;
    }

    public function get_sign() {
        $res = '';
        $_ts = time();
        $_ts -= 60;
        #$_date = date('Y-m-d H:00:00');
        #$_ts = strtotime($_date);
        $_arr_header = array('alg'=>'ES256', 'kid'=>$this->auth_key_id);
        $_arr_claims = array('iss'=>$this->team_id, 'iat'=>$_ts);
        $_str_header = json_encode($_arr_header, JSON_UNESCAPED_SLASHES);
        $_str_claims = json_encode($_arr_claims, JSON_UNESCAPED_SLASHES);
        
        $_jwt_header = $this->base64_encode_safe($_str_header);
        $_jwt_claims = $this->base64_encode_safe($_str_claims);

        $_str_to_be_sign = sprintf('%s.%s', $_jwt_header, $_jwt_claims);

        $_shell = 'printf '.$_str_to_be_sign.'|' . $this->openssl . ' dgst -binary -sha256 -sign ' . $this->auth_key . '';
        $_res_shell = exec($_shell);
        $_res_shell = $this->base64_encode_safe($_res_shell);
        $res = sprintf('%s.%s.%s', $_jwt_header, $_jwt_claims, $_res_shell);

        return $res;
    }

    public function base64_encode_safe($data = '') {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    public function base64_decode_safe($data = '') {
        return base64_decode(strtr($data, '-_', '+/'));
    }

}
