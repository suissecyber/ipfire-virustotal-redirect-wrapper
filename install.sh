#!/bin/bash

#### VIRUSTOTAL REDIRECTOR

# Backup and copy of the "virustotal" file
FILE_TO_COPY="redirectors/virustotal"
DEST_FILE="/usr/bin/virustotal"

if [[ -f "$DEST_FILE" ]]; then
  BACKUP_FILE="${DEST_FILE}.bak"
  echo "The file $DEST_FILE already exists. Creating a backup in $BACKUP_FILE."
  cp "$DEST_FILE" "$BACKUP_FILE" || { echo "Error creating the backup of $DEST_FILE"; exit 1; }
fi

if [[ -f "$FILE_TO_COPY" ]]; then
  echo "Copying $FILE_TO_COPY to $DEST_FILE."
  cp "$FILE_TO_COPY" "$DEST_FILE" || { echo "Error copying $FILE_TO_COPY"; exit 1; }
  chmod +x "$DEST_FILE" # Makes the copied file executable
else
  echo "Error: The file $FILE_TO_COPY does not exist!"
  exit 1
fi

#### VIRUSTOTAL LOG

# Path to the log file
LOG_DIR="/var/log/virustotal"
LOG_FILE="$LOG_DIR/squid_redirector.log"

# Ensure the log directory exists
if [[ ! -d "$LOG_DIR" ]]; then
  echo "Creating log directory: $LOG_DIR"
  mkdir -p "$LOG_DIR" || { echo "Error creating directory $LOG_DIR"; exit 1; }
fi

# Create the log file if it doesn't exist
if [[ ! -f "$LOG_FILE" ]]; then
  echo "Creating log file: $LOG_FILE"
  touch "$LOG_FILE" || { echo "Error creating log file $LOG_FILE"; exit 1; }
fi

# Set ownership and permissions
echo "Setting ownership and permissions for $LOG_FILE"
chown squid:squid "$LOG_FILE" || { echo "Error setting ownership for $LOG_FILE"; exit 1; }
chmod u+w "$LOG_FILE" || { echo "Error setting permissions for $LOG_FILE"; exit 1; }

echo "Log file setup completed: $LOG_FILE"


#### PATCH FILE FOR PLUGIN

# Paths to the files
FILE_REDIRECT="/usr/sbin/redirect_wrapper"
FILE_PROXY="/srv/web/ipfire/cgi-bin/proxy.cgi"
FILE_PROXY_BACKUP="/srv/web/ipfire/cgi-bin/proxy.cgi.bak"
FILE_TEMP="/tmp/proxy_temp.cgi"

# --- Modifications to redirect_wrapper ---
# Line to add to redirect_wrapper (pushing VirusTotal to the redirectors array)
LINE_REDIRECT_ADD='		push(@redirectors, "/usr/bin/virustotal");'
# Line targeting the existing squidGuard entry (used for reference for insertion)
LINE_REDIRECT_TARGET='push(@redirectors, "/usr/bin/squidGuard");'

# Check if the line to add already exists in redirect_wrapper
if grep -qF "$LINE_REDIRECT_ADD" "$FILE_REDIRECT"; then
  echo "redirect_wrapper: Line already present."
else
  # Escape special characters in target and add lines using sed. This prevents issues if the target line contains special regex characters.
  printf -v escaped_target '%s' "$LINE_REDIRECT_TARGET"
  printf -v escaped_line '%s' "$LINE_REDIRECT_ADD"
  sed -i "\|$escaped_target|i $escaped_line" "$FILE_REDIRECT" || { echo "Error adding to redirect_wrapper"; exit 1; }
  echo "redirect_wrapper: Line added."
fi

# --- Modifications to proxy.cgi ---

# Backup the original file
if [[ ! -f "$FILE_PROXY" ]]; then
  echo "Error: $FILE_PROXY does not exist!"
  exit 1
fi
cp "$FILE_PROXY" "$FILE_PROXY_BACKUP" || { echo "Error backing up $FILE_PROXY"; exit 1; }

# Definitions to add (VirusTotal safe search engines, MIME types, and extensions)
DEFINITIONS="
my \$def_virustotal_safe_search_engines=\"google.com bing.com yahoo.com duckduckgo.com search.com search.yahoo.com gstatic.com youtube.com ytimg.com googleusercontent.com gstatic.com apis.google.com\";
my \$def_virustotal_mime_types=\"application/pdf application/zip application/x-msdownload\";
my \$def_virustotal_extensions=\".pdf .doc .docx .xls .xlsx .ppt .pptx .zip .rar .exe .bat .elf .sh .vbs .vbe .hta .lnk\";
"

# New HTML block to add (enabling VirusTotal filter checkbox in the web interface)
NEW_BLOCK="
if ( -e \"/usr/bin/virustotal\" ) {
print \"</td>\";
print \"<td class='base'><b>VirusTotal filter</b><br />\";
print \$Lang::tr{'advproxy enabled'} . \"<input type='checkbox' name='ENABLE_VIRUSTOTAL' \" . \$checked{'ENABLE_VIRUSTOTAL'}{'on'} . \" /><br />\";
}
"

# Additional HTML snippet to insert before the second <hr size='1'>
NEW_HTML_SNIPPET="
END
;
if ( \$proxysettings{'ENABLE_VIRUSTOTAL'} eq 'on' ){
print <<END
<hr size='1'>
<table width='100%'>
<tr>
    <td colspan='4' class='base'><b>VirusTotal filter</b></td>
</tr>
<tr>
    <td width='40%' class='base'>VirusTotal API Key:</td>
    <td><input type='text' size='80' name='VIRUSTOTAL_API_KEY' value='
END
;
if (\$proxysettings{'VIRUSTOTAL_API_KEY'}) { print \$proxysettings{'VIRUSTOTAL_API_KEY'}; }
print <<END
' /></td>
    <td colspan='2'>&nbsp;</td>
</tr>
<tr>
    <td class='base'>Check File Extensions (whitespace separator):</td>
    <td colspan='3'><textarea name='VIRUSTOTAL_EXTENSIONS' rows='4' cols='100'>
END
;
if (!\$proxysettings{'VIRUSTOTAL_EXTENSIONS'}) { print \$def_virustotal_extensions; } else { print \$proxysettings{'VIRUSTOTAL_EXTENSIONS'}; }
print <<END
</textarea></td>
</tr>
<tr>
    <td class='base'>\$Lang::tr{'advproxy MIME filter'} \$Lang::tr{'advproxy enabled'}:</td>
    <td><input type='checkbox' name='VIRUSTOTAL_ENABLE_MIME_FILTER' \$checked{'VIRUSTOTAL_ENABLE_MIME_FILTER'}{'on'} /></td>
    <td colspan='2'>&nbsp;</td>
</tr>
<tr>
    <td class='base'>Check MIME Types (whitespace separator):</td>
    <td colspan='3'><textarea name='VIRUSTOTAL_MIME_TYPES' rows='4' cols='100'>
END
;
if (!\$proxysettings{'VIRUSTOTAL_MIME_TYPES'}) { print \$def_virustotal_mime_types; } else { print \$proxysettings{'VIRUSTOTAL_MIME_TYPES'}; }
print <<END
</textarea></td>
</tr>
<tr>
    <td class='base'>Safe Search Engines (whitespace separator):</td>
    <td colspan='3'><textarea name='VIRUSTOTAL_SAFE_SEARCH_ENGINES' rows='6' cols='100'>
END
;
if (!\$proxysettings{'VIRUSTOTAL_SAFE_SEARCH_ENGINES'}) { print \$def_virustotal_safe_search_engines; } else { print \$proxysettings{'VIRUSTOTAL_SAFE_SEARCH_ENGINES'}; }
print <<END
</textarea></td>
</tr>
</table>

END
;
}
print <<END
"

# Other modifications grouped for efficiency using awk
NEW_LINE="	\$proxysettings{'ENABLE_VIRUSTOTAL'} = 'off';\n\$proxysettings{'VIRUSTOTAL_ENABLE_MIME_FILTER'} = 'off';\n\$proxysettings{'VIRUSTOTAL_API_KEY'} = '';"
MODIFIED_CONDITION="if((\$proxysettings{'ENABLE_FILTER'} eq 'on') || (\$proxysettings{'ENABLE_UPDXLRATOR'} eq 'on') || (\$proxysettings{'ENABLE_CLAMAV'} eq 'on') || (\$proxysettings{'ENABLE_VIRUSTOTAL'} eq 'on'))"
STDPROXY_LINE=" \$stdproxysettings{'ENABLE_VIRUSTOTAL'} = \$proxysettings{'ENABLE_VIRUSTOTAL'};"
CHECKED_LINES="
\$checked{'ENABLE_VIRUSTOTAL'}{'off'} = '';\n\$checked{'ENABLE_VIRUSTOTAL'}{'on'} = '';\n\$checked{'ENABLE_VIRUSTOTAL'}{\$proxysettings{'ENABLE_VIRUSTOTAL'}} = \"checked='checked'\";
\$checked{'VIRUSTOTAL_ENABLE_MIME_FILTER'}{'off'} = '';\n\$checked{'VIRUSTOTAL_ENABLE_MIME_FILTER'}{'on'} = '';\n\$checked{'VIRUSTOTAL_ENABLE_MIME_FILTER'}{\$proxysettings{'VIRUSTOTAL_ENABLE_MIME_FILTER'}} = \"checked='checked'\";
"

# Use awk to perform multiple modifications in a single pass for better performance
awk -v defs="$DEFINITIONS" \
    -v block="$NEW_BLOCK" \
    -v snippet="$NEW_HTML_SNIPPET" \
    -v newline="$NEW_LINE" \
    -v newcondition="$MODIFIED_CONDITION" \
    -v stdline="$STDPROXY_LINE" \
    -v chklines="$CHECKED_LINES" '
    BEGIN { hr_count = 0 }
    /my \$def_ports_ssl="443 # https\\n563 # snews\\n";/ {
        print;
        print defs;
        next;
    }
    /<\/td><\/tr>/ && !html_block_added {
        print block;
        html_block_added = 1;
    }
    /<hr size='\''1'\''>/ {
        hr_count++;
        if (hr_count == 2) {
            print snippet;
        }
    }
    /\$proxysettings\{'\''ENABLE_CLAMAV'\''\} = '\''off'\'';/ && !settings_added {
        print;
        print newline;
        settings_added = 1;
        next;
    }
    /\(\$proxysettings\{'\''ENABLE_FILTER'\''\} eq '\''on'\''\) \|\| \(\$proxysettings\{'\''ENABLE_UPDXLRATOR'\''\} eq '\''on'\''\) \|\| \(\$proxysettings\{'\''ENABLE_CLAMAV'\''\} eq '\''on'\''\)/ {
        print newcondition;
        next;
    }
    /\$stdproxysettings\{'\''ENABLE_CLAMAV'\''\} = \$proxysettings\{'\''ENABLE_CLAMAV'\''\};/ && !std_added {
        print;
        print stdline;
        std_added = 1;
        next;
    }
    /\$checked\{'\''ENABLE_CLAMAV'\''\}\{\$proxysettings\{'\''ENABLE_CLAMAV'\''\}\} = "checked='\''checked'\''";/ && !checked_added {
        print;
        print chklines;
        checked_added = 1;
        next;
    }
    { print } # Print all other lines
' "$FILE_PROXY" > "$FILE_TEMP" || { echo "Error modifying $FILE_PROXY"; exit 1; }

mv "$FILE_TEMP" "$FILE_PROXY" || { echo "Error overwriting $FILE_PROXY"; exit 1; }
chmod +x "$FILE_PROXY"

echo "proxy.cgi: Modifications completed. Backup created as $FILE_PROXY_BACKUP"
