<?php
  date_default_timezone_set('UTC');
  $length=50000;
  if (isset($_GET['length'])) {
    $length = $_GET['length'];
  }

  $source="not_specified";
  if (isset($_GET['source'])) {
    $source = $_GET['source'];
  }

  $file="hook.txt";
  $contents = @file_get_contents('php://input');
  $request = date('Y-m-d H:i:s') . ",   REMOTE_ADDR=$_SERVER[REMOTE_ADDR],   SOURCE=$source".
                                   ",   CONTENT=" . prettyPrint( $contents ) . " \n\n";
  echo "Wrote output to /$file base on GET parameters:<br /> source=$source<br /> length=$length";

  # Add the content at the beginning
  $temp = file_get_contents($file);
  $content = $request.$temp;

  # Write back into the log first X characters
  file_put_contents($file, substr($content, 0, $length));


  // From: http://stackoverflow.com/questions/6054033/pretty-printing-json-with-php
  function prettyPrint( $json )
  {
    $result = '';
    $level = 0;
    $in_quotes = false;
    $in_escape = false;
    $ends_line_level = NULL;
    $json_length = strlen( $json );

    for( $i = 0; $i < $json_length; $i++ ) {
        $char = $json[$i];
        $new_line_level = NULL;
        $post = "";
        if( $ends_line_level !== NULL ) {
            $new_line_level = $ends_line_level;
            $ends_line_level = NULL;
        }
        if ( $in_escape ) {
            $in_escape = false;
        } else if( $char === '"' ) {
            $in_quotes = !$in_quotes;
        } else if( ! $in_quotes ) {
            switch( $char ) {
                case '}': case ']':
                    $level--;
                    $ends_line_level = NULL;
                    $new_line_level = $level;
                    break;

                case '{': case '[':
                    $level++;
                case ',':
                    $ends_line_level = $level;
                    break;

                case ':':
                    $post = " ";
                    break;

                case " ": case "\t": case "\n": case "\r":
                    $char = "";
                    $ends_line_level = $new_line_level;
                    $new_line_level = NULL;
                    break;
            }
        } else if ( $char === '\\' ) {
            $in_escape = true;
        }
        if( $new_line_level !== NULL ) {
            $result .= "\n".str_repeat( "\t", $new_line_level );
        }
        $result .= $char.$post;
    }
    return $result;
  }

?>
