<?php
/*
 Copyright 2015-2016 Open Platform for NFV Project, Inc. and its contributors
  
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
  
 http://www.apache.org/licenses/LICENSE-2.0
  
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/
$method = $_SERVER['REQUEST_METHOD'];
if ($method == 'OPTIONS') {
	header("Content-Type: application/json");
	header("Access-Control-Allow-Origin: *");
	header("Access-Control-Allow-Headers: Content-Type");
	header("Access-Control-Allow-Methods: GET, POST, DELETE");
	exit();
}

$url = "http://CONGRESS_HOST:1789".$_GET['~url'];
$curlop = curl_init();
curl_setopt($curlop, CURLOPT_URL, $url);
curl_setopt($curlop, CURLOPT_CUSTOMREQUEST, $method);
//curl_setopt($curlop, CURLOPT_HEADER, 0);
//curl_setopt($curlop, CURLINFO_HEADER_OUT, 0);
curl_setopt($curlop, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($curlop, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($curlop, CURLINFO_HEADER_OUT, true);

if ($method == "POST") {
	curl_setopt($curlop, CURLOPT_HTTPHEADER, array("Content-Type: application/json"));
	$body = file_get_contents('php://input');
	curl_setopt($curlop, CURLOPT_POSTFIELDS, $body);
}

$response = curl_exec($curlop);
$req_time=time();

$info = curl_getinfo($curlop);
$result = file_put_contents("/home/ubuntu/logs/".date('ymd').".log", "proxy.php, ".$req_time.", ".$url.", ".$type.", ".$body."\n",FILE_APPEND);
if ($result === false) $response = "PHP error in index.php";
$responseCode=curl_getinfo($curlop,CURLINFO_HTTP_CODE);
$header_size = curl_getinfo($response, CURLINFO_HEADER_SIZE);
$header = substr($response, 0, $header_size);
$type = curl_getinfo($curlop,CURLINFO_CONTENT_TYPE);
$body = substr($response, $header_size);
$result = file_put_contents("/home/ubuntu/logs/".date('ymd').".log", "proxy.php, ".$req_time.", ".$responseCode.", ".$type.", ".$header.", ".$body."\n",FILE_APPEND);
if ($result === false) $response = "PHP error in index.php";

//    header("Location: ".$url);
header("Content-Type: ".$type);
header("Access-Control-Allow-Origin: *");
echo $response;
curl_close($curlop);
