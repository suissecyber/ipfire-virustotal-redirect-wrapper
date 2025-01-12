VirusTotal Integration for IPFire 2.29
=============================

This project integrates VirusTotal scanning functionality into the [IPFire 2.29](https://www.ipfire.org/) firewall system. By adding a redirector and modifying the existing proxy configuration, it enables advanced scanning of traffic and file extensions using VirusTotal's API.

This project is dependent on the [IPFire SSL-Bump](https://github.com/suissecyber/ipfire-ssl-bump), which is required to enable SSL inspection capabilities necessary for this integration.

Features
--------

*   **VirusTotal Integration**: Scans specific file types and MIME types using VirusTotal.
*   **Safe Search Engines**: Adds customizable safe search engines.
*   **Proxy Web Interface Enhancements**: Provides configuration options in the IPFire web interface.
*   **Logging**: Creates dedicated logs for VirusTotal operations.
*   **Customizable Rules**: Allows defining file extensions and MIME types for scanning.

* * *

Prerequisites
-------------

1.  IPFire 2.29 installed and operational.
2.  The [IPFire SSL-Bump](https://github.com/suissecyber/ipfire-ssl-bump) module installed and configured.

* * *

Installation
------------

1.  **Download and Prepare the Files**: Clone this repository or download the script directly.
    
    ```bash
    pakfire install -y git
    git clone https://github.com/suissecyber/ipfire-virustotal-redirect-wrapper.git
    cd ipfire-virustotal-redirect-wrapper
    ``` 
    
2.  **Run the Installer**: Execute the installation script to copy necessary files, create backups, and apply changes.
    
    ```bash
    chmod +x install.sh
    sudo ./install.sh
    ``` 
    
    The script will:
    
    *   Copy the VirusTotal redirector to `/usr/bin/virustotal`.
    *   Set up the log file at `/var/log/virustotal/squid_redirector.log`.
    *   Apply modifications to the `redirect_wrapper` and `proxy.cgi` files.
4.  **Configure Permissions**: Ensure all files have the correct permissions. The script manages this automatically.
    

* * *

Usage
-----

1.  **Configure VirusTotal**:
    
    *   Open the IPFire web interface.
    *   Navigate to the **Web Proxy Settings**.
    *   Locate the new "VirusTotal filter" section.
    *   Enable the filter and provide a valid VirusTotal API key.
    *   Define file extensions, MIME types, and safe search engines as needed.
2.  **View Logs**:
    
    *   Logs are stored in `/var/log/virustotal/squid_redirector.log`.

## Contributing
Feel free to fork this repository, open issues, or submit pull requests to improve the script or add new features.

## License
This project is licensed under the [GPL-3.0 License](https://www.gnu.org/licenses/gpl-3.0.en.html).
