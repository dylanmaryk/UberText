<?php
	mysql_connect('YOUR_HOST', 'YOUR_USERNAME', 'YOUR_PASSWORD'); # Add your own MySQL server details
	mysql_select_db('YOUR_DATABASE'); # Add your own MySQL server details

	$number = $_POST["fieldNumber"];
	$authCode = $_POST["fieldAuthCode"];

	$ch = curl_init();

	curl_setopt($ch, CURLOPT_URL,"https://login.uber.com/oauth/token");
	curl_setopt($ch, CURLOPT_POST, 1);
	curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query(array(
		'client_secret' => 'YOUR_CLIENT_SECRET', # Add your own Uber client secret
		'client_id' => 'YOUR_CLIENT_ID', # Add your own Uber client ID
		'grant_type' => 'authorization_code',
		'redirect_uri' => 'YOUR_WEBSITE/step2.html', # Add your own website URL, ensure the entire redirect URI matches the redirect URL you provide in your Uber app settings
		'code' => $authCode
	)));
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

	$result = curl_exec($ch);
	$json = json_decode($result, true);
	$bearer = $json['access_token'];

	curl_close($ch);

	mysql_query("INSERT INTO UberText_Numbers (Number, Bearer) VALUES ('$number', '$bearer') ON DUPLICATE KEY UPDATE Bearer = '$bearer'");
?>