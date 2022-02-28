<?php

require_once 'vendor/autoload.php';

function curl_url($url, $data)
{
  $payload = json_encode($data);
  $ch = curl_init();

  curl_setopt($ch, CURLOPT_URL, $url);
  curl_setopt($ch, CURLOPT_POST, 1);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($ch, CURLOPT_TIMEOUT, 5);
  curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
  curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);

  print("\n==== Posting to Slack ====\n");

  $result = curl_exec($ch);
  print("RESULT: $result");
  // $payload_pretty = json_encode($post,JSON_PRETTY_PRINT); // Uncomment to debug JSON
  // print("JSON: $payload_pretty"); // Uncomment to Debug JSON

  print("\n===== Post Complete! =====\n");
  curl_close($ch);
}

// Process results
try {
  $results = file('/tmp/results.txt');

  if ($results !== FALSE) {
    // Initiate Slack
    $url = getenv('SLACK_WEBHOOK');
    $data = [
      'username' => 'Github Actions',
      'icon_emoji' => ':crystal_ball:',
      'text' => ":tada: Bulk Parallel deployments complete! ".count($results)." sites deployed."
    ];   
    curl_url($url, $data);
  }
} catch (Exception $e) {
  echo $e->getMessage();
}
