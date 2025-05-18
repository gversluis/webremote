<?php
	set_error_handler(function(int $errno, string $errstr) {
		if (strpos($errstr, 'Undefined array key') === false) {
			return false;
		} else {
			return true;
		}
	}, E_WARNING);

	$json = [];
	$action = $_GET['action'];
	$output = asyncExec($action, 1);
	if (stristr($_SERVER['HTTP_ACCEPT'], '/json') || stristr($_GET['output'], 'json')) {
		header('Content-Type: application/json');
		print $output;
		exit;
	} else if (stristr($_GET['output'], 'text')) {
		$json = json_decode($output, true, JSON_INVALID_UTF8_SUBSTITUTE);
		header('Content-Type: text/plain');
		if (!$json['audacity'] && !$json['kodi']) {
			print "Nothing playing";
		} else if (!$json['audacity']) {
			print 'Kodi?';
		} else {
			$output = $json['nowplaying'].' '.$json['progress'].'%';
			print str_replace("\n", "            ", $output);
		}
		exit;
	} else {
		$json = json_decode($output, true, JSON_INVALID_UTF8_SUBSTITUTE);
		if (!isset($json['duration']) || !$json['duration']) $json['duration'] = 0.01;	// so we don't devide by 0
		if (!isset($json['progress']) || !$json['progress']) $json['progress'] = 0.01;	// so we don't devide by 0
		$refresh = $json['duration']-$json['progress'];
		if ($refresh <= 0) $refresh = 600; // when song ends
	}
	
	function getExecutableFromJson($jsonFilename) {
		$json = file_get_contents($jsonFilename);
		return json_decode($json, true)["exec"];
	}

	function asyncExec($action, $timeout) {
		set_time_limit($timeout*2);	// so we can still check the fallback

		$descriptorspec = array(
			array('pipe', 'r'),	// stdin is a pipe that the child will read from
			array('pipe', 'w'),	// stdout is a pipe that the child will write to
			array('pipe', 'w'),	// stdout is a pipe that the child will write to
		);

		$exec = getExecutableFromJson('data/remote.json');
		$userid = fileowner($exec);
		$process = proc_open("sudo -u \#$userid $exec $action", $descriptorspec, $pipes);
		# if you can/do not use sudo you can use chmod u+s remote executable instead. Be aware that this does not work for scripts (shebang) so you need a compiled executable
		# $process = proc_open("/var/www/remote/remote.sh ".$action, $descriptorspec, $pipes);
		$start = time();
		$output = '';
		$timedOut = false;

		// so it ends script even if background processes are still going :(
		if (is_resource($process)) {
			$status=proc_get_status($process);
			posix_setpgid($status['pid'], $status['pid']);
			stream_set_blocking($pipes[0], 0);
			stream_set_blocking($pipes[1], 0);
			stream_set_blocking($pipes[2], 0);
			fclose($pipes[0]);

			while ($status['running']) {
				$output .= stream_get_contents($pipes[1]);
				// print stream_get_contents($pipes[2]);
				$status=proc_get_status($process);

				if (!$timedOut && time()-$start>$timeout) {	// sometimes the loop is faster than killing and one time is enough
					$timedOut = true;
					//proc_terminate($process, 9);    //only terminate subprocess, won't terminate sub-subprocess
					if ($action !== 'status.text') asyncExec('status.text', 1);	// so we get at least a status
					posix_kill(-$status['pid'], 9);    //sends SIGKILL to all processes inside group(negative means GPID, all subprocesses share the top process group, except nested my_timeout_exec)
				}
			}
			fclose($pipes[1]);
			fclose($pipes[2]);
			proc_close($process);
		} else {
			print "No process?!";
		}
		return $output;
	}

?>
<!DOCTYPE HTML>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Remote status</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta http-equiv="refresh" content="<?=$refresh?>;url=?action=status.text">
	<title>Remote</title>
	<link rel="icon" type="image/x-icon" href="favicon.png">
	<style>

@keyframes audacityprogress {
	from {
		transform: translateX(-<?=100-($json['progress']/$json['duration']*100)?>%);
	}
	to {
		transform: translateX(0);
	}
}


html,
body {
	height: 100%;
	background: #000;
	color: #ccc;
	width: 100%;
	margin: 0;
	padding: 0;
}

.title {
	padding: 2mm;
}

.progress {
	position: absolute;
	bottom: 4px;
	width: 100%;
}
.progress .audacity.running {
	display: block;
	height: 4px;
	background: orange;
	transform: translateX(-<?=100-($json['progress']/$json['duration']*100)?>%);
	animation-duration: <?=$json['duration']-$json['progress']?>s;
	animation-timing-function: linear;
	animation-name: audacityprogress;
	will-change: transform;
}
.progress .kodi.running {
	display: block;
	height: 4px;
	background: #546fff;
	transform: translateX(-<?=100-($json['progress']/$json['duration']*100)?>%);
	animation-duration: <?=$refresh?>s;
	animation-timing-function: linear;
	animation-name: kodiprogress;
	will-change: transform;
}


	</style>
</head>
<body>
	<!-- <?=print_r($json)?> -->
	<div class="remotestatus">
		<div class="radio"></div>
		<div id="title" class="title"><?=nl2br(htmlentities($json['nowplaying']))?></div>
		<div class="progress">
			<div class="kodi <?=$json['kodi']?'running':'off'?>"></div>
			<div class="audacity <?=$json['audacity']?'running':'off'?>"></div>
		</div>
	</div>
	<script type="text/javascript">
		setTimeout(function() {
			window.location = "?action=status.text";
		}, <?=$refresh*1000?>);
	</script>
</body>
</html>


