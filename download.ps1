cls
[int]$dwcount = 0
[int]$counter = 0
$i32 = "no"
################ Download EXE function definition #####################

function downloadfile($dwdetails, $hashfile)
{
    #$dwdir = get-location
	$dwdir = "F:\CEROW-ApplicationSource\Symantec Intelligent Updater\downloader"
    #$weblink = "http://www.symantec.com/security_response/definitions/download/detail.jsp?gid=savce"
    #$weblink = "https://www.symantec.com/security_response/definitions/download/detail.jsp?gid=sep"
    #$weblink = "https://www.symantec.com/security_response/definitions/download/detail.jsp?gid=sonar"
    #$weblink = "https://www.symantec.com/security_response/definitions/download/detail.jsp?gid=ips"

    $weblinks = ("https://www.symantec.com/security_response/definitions/download/detail.jsp?gid=ips", `
                "https://www.symantec.com/security_response/definitions/download/detail.jsp?gid=sonar",`
                "https://www.symantec.com/security_response/definitions/download/detail.jsp?gid=sep",`
                "https://www.symantec.com/security_response/definitions/download/detail.jsp?gid=sep")

    $client = new-object System.Net.WebClient
    $client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    
    foreach ($weblink in $weblinks) {
        $dwcount = 0
        Write-output "Obtaining download details from $weblink"
        $dwdetails = "$dwdir\details.txt"

        $client.DownloadFile($weblink, $dwdetails)

        $hashmd5 = "http://www.symantec.com/avcenter/download/md5-hash.txt"
        $hashfile = "$dwdir\md5-hash.txt"
        $client.DownloadFile($hashmd5, $hashfile)

        $str = findstr ".exe" $dwdetails
        $data = $($str[1]).split("<")
        $req = "$($data[3])"
        $final = $req.split(">")
        $filename = $($final[1])
        if ($weblink -like "*gid=sep*") {
            if ($i32 -eq "yes") {
                $filename = $filename -replace "i32","i64"
            }
        }
        #$url="ftp://ftp.symantec.com/public/english_us_canada/antivirus_definitions/norton_antivirus/jdb/$jdbname"
        if ($weblink -like "*gid=ips*") {
            $type = "ips/"
         }
        elseif ($weblink -like "*gid=sonar*") {
            $type = "sonar/"
        }
        else {
            $type = ""
        }
        $url="http://definitions.symantec.com/defs/$type$filename"

        [int]$dwcount = 0
        Do {
            Write-output "Downloading EXE from $url"
            $dest="$dwdir\$filename"
            #Write-Output "Saving to file $dest"
            $client.DownloadFile($url, $dest) 2> $null
            $detail = get-content $hashfile | findstr $filename
            $symhash = "$detail".split(" ")
            if ($symhash[1] -like "*$type*") {
            } else {
                $symhash[0] = $symhash[2]
            }
            fciv -md5 $dest | findstr .exe | %{$filehash = $_.split(" ")}
            if ($($symhash[0]) -eq $($filehash[0])) {
                Write-output "$filename download successful"
                Write-output " "
                if ($weblink -like "*gid=sep*") {
                    $i32 = "yes"
                }
                $counter = $counter + 1
                $dwcount = 3
            } elseif ($dwcount -lt 3) {
                Write-Output "$filename download unsuccessful. Attempting to download again...."
                $dwcount = $dwcount+1
                #downloadfile($dwdetails, $hashfile)
            } else {
                Write-Output "$filename download unsuccessful. Skipped"
                Write-output " "
            }
        }
        Until ($dwcount -eq 3)
        
        #$filename = ""
        #$type = ""
        del $hashfile
        del $dwdetails 

    }  
    
    if ($counter -eq 4) {
		cd $dwdir
        del ..\2017*.exe
        Move-Item 2017*.exe ..\
    }

}

#######################################################################

downloadfile($dwdetails, $hashfile)
start-sleep 5