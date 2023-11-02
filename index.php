<!DOCTYPE html>
<?php
	function jsonFileToHtml($jsonFilename) {
		$json = file_get_contents($jsonFilename);
		$buttons = json_decode($json, true)["buttons"];
		buttonsToHtml($buttons);
	}

	/* recursive function */
	function buttonsToHtml($buttons, $prefixes=array()) {
		foreach($buttons as $key => $value) {
			if (gettype($value) === 'array' && array_key_exists('exec', $value)) {
				if ($value['exec'])
					print("\t".'<a class="'.implode(' ', $prefixes).' '.$key.'" href="exec.php?action='.implode('.', $prefixes).'.'.$key.'" target="status" data-function="'.$value["text"].'"></a>'."\n");
			} else {
				print "<div class=\"$key\">\n";
				array_push($prefixes, $key);
				if (gettype($value) === 'array') buttonsToHtml($value, $prefixes);
				array_pop($prefixes);
				print "</div>\n";
			}
		}
	}
?>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Remote</title>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="remote.css?v1"></style>
	<link rel="icon" type="image/x-icon" href="favicon.png">
	<link rel="manifest" href="manifest.webmanifest" crossorigin="use-credentials">

</head>
<body>
	<div class="skin">
		<iframe id="status" name="status" width="100%" src="exec.php?action=status"></iframe>
<?=jsonFileToHtml('data/remote.json') // could be done with JavaScript but I want to avoid extra requests and using power of clients ?>
	</div>
	<script type="text/javascript">
		let button = document.createElement('button');
		button.innerText = '📋 ';
		button.className = 'clipboard';
		button.onclick = function() {
			let frameObj = document.getElementById('status');
			let frameContent = frameObj.contentWindow.document.getElementById('title').innerText.replace(/\n.*./, "");
			navigator.clipboard.writeText(frameContent);
		}
		document.getElementById('status').insertAdjacentElement('afterend', button);
	</script>
</body>
</html>
