#!/bin/sh

# User Configuration
email='name@example.com'
password='nutella123'

minimum_pdf_size=5000000 # minimum file size to check if downloaded file is a valid pdf
wait_between_downloads=3 # wait a few seconds between repetitions on errors to prevent rate limiting
max_tries_per_download=3 # if a download fails (or is not a valid pdf), repeat this often

max_nr_of_magazines_per_year=27

echo 'Heise Magazine Downloader v1.0'

usage()  
{  
    echo "Usage: $0 [-v] <ct|make|ix|retro-gamer|...> year [end_year=year]"
    echo "Example: $0 ct 2022"
    echo "Example: $0 ct 2011 2022"
    echo "-v: Verbose Output"
    exit 1  
} 

verbose=false

while getopts v name
do
    case $name in
    v)  verbose=true;;
    ? | h)  usage
        exit 2;;
    esac
done

shift $(($OPTIND -1))

if [ "$2" = "" ]; then
    usage
fi

$verbose && silent_param='' || silent_param='-s'

magazine=${1}
start_year=${2}
if [ "$3" = "" ]; then
    end_year=${start_year}
else
    end_year=${3}
fi

curl_session_file="/tmp/curl_session$(date +%s)"
count_success=0
count_fail=0
count_skip=0
info="[\033[0;36mINFO\033[0m]"

# Login
echo "Logging in..."
curl --no-progress-meter -b ${curl_session_file} -c ${curl_session_file} -k -L "https://www.heise.de/sso/login" >/dev/null 2>&1
curl --no-progress-meter -b ${curl_session_file} -c ${curl_session_file} -k -L -F 'forward=' -F "username=${email}" -F "password=${password}" -F 'ajax=1' "https://www.heise.de/sso/login/login" -o ${curl_session_file}.html
token1=$(cat ${curl_session_file}.html | sed "s/token/\ntoken/g" | grep ^token | head -1 | cut -f 3 -d '"')
token2=$(cat ${curl_session_file}.html | sed "s/token/\ntoken/g" | grep ^token | head -2 | tail -1 | cut -f 3 -d '"')
curl --no-progress-meter -b ${curl_session_file} -c ${curl_session_file} -k -L -F "token=${token1}" "https://m.heise.de/sso/login/remote-login" >/dev/null 2>&1
curl --no-progress-meter -b ${curl_session_file} -c ${curl_session_file} -k -L -F "token=${token2}" "https://shop.heise.de/customer/account/loginRemote" >/dev/null 2>&1

# Download PDFs and Thumbnails
for year in $(seq -f %g ${start_year} ${end_year}); do
    $verbose && printf "${info} YEAR ${year}\n" 
    for i in $(seq -f %g 1 ${max_nr_of_magazines_per_year}); do
        $verbose && printf "${info} ISSUE ${i}\n" 
        i_formatted=$(printf "%02d" ${i})
        file_base_path="${magazine}/${year}/${magazine}.${year}.${i_formatted}"
        actual_pdf_size=0
        downloads_tried=1
        logp="[${magazine}][${year}/${i_formatted}]"
        if [ ! -f "${file_base_path}.pdf" ]; then
            $verbose && printf "${log}${info} Downloading Thumbnail\n" 
            curl ${silent_param} -b ${curl_session_file} -f -k -L --retry 99 "https://heise.cloudimg.io/v7/_www-heise-de_/select/thumbnail/${magazine}/${year}/${i}.jpg" -o "${file_base_path}.jpg" --create-dirs
            if [ $? -eq 22 ]; then
                echo "${logp}[\033[0;33mSKIP\033[0m] Magazine issue does not exist on the server, skipping."
            else
                $verbose && printf "${log}${info} Thumbnail downloaded\n" 
                until [ ${actual_pdf_size} -gt ${minimum_pdf_size} ] || [ ${downloads_tried} -gt ${max_tries_per_download} ]; do
                    try="[TRY ${downloads_tried}/${max_tries_per_download}]"
                    $verbose && printf "${log}${try}${info} Downloading Header\n"
                    content_type=$(curl ${silent_param} -f -I -b ${curl_session_file} -k -L "https://www.heise.de/select/${magazine}/archiv/${year}/${i}/download")
                    response_code=$?
                    content_type=$(echo "${content_type}" | grep -i "^Content-Type: " | cut -c15- | tr -d '\r')
                    if [ ${response_code} -eq 22 ]; then
                        echo "${logp}${try} Server refused connection, you might not be allowed to download this issue."
                        sleep ${wait_between_downloads}
                    elif [ "${content_type}" = 'binary/octet-stream' ]; then
                        echo "${logp} Downloading..."
                        actual_pdf_size=$(curl -# -b ${curl_session_file} -f -k -L --retry 99 "https://www.heise.de/select/${magazine}/archiv/${year}/${i}/download" -o "${file_base_path}.pdf" --create-dirs -w '%{size_download}')
                        # actual_pdf_size=$(wc -c < "${file_base_path}.pdf")
                        if [ ${actual_pdf_size} -lt ${minimum_pdf_size} ]; then
                            echo "${logp}${try} Downloaded file is too small (size: ${actual_pdf_size}/${minimum_pdf_size})."
                            sleep ${wait_between_downloads}
                        else
                            echo "${logp}[\033[0;32mSUCCESS\033[0m] Downloaded ${file_base_path}.pdf (size: ${actual_pdf_size})"
                        fi
                    else
                        echo "${logp}${try} Server did not serve a valid pdf (instead ${content_type})."
                        sleep ${wait_between_downloads}
                    fi
                    downloads_tried=$((downloads_tried+1))
                done
                if [ ! -f "${file_base_path}.pdf" ]; then
                    printf "${logp}[\033[0;31mERROR\033[0m] Could not download magazine issue. Please try again later.\n"
                    count_fail=$((count_fail+1))
                else
                    $verbose && printf "${log}${info} Finished Succesfully\n"
                    count_success=$((count_success+1))
                fi
            fi
        else
            echo "${logp}[\033[0;33mSKIP\033[0m] Already downloaded."
            count_skip=$((count_skip+1))
        fi
    done
done

# Summary
echo "Summary: ${count_success} files downloaded succesfully, ${count_fail} failed, ${count_skip} were skipped."

# Cleanup Temp Session
if [ -f "${curl_session_file}" ]; then
    $verbose && printf "${info} Clearing Session\n"
    rm ${curl_session_file}.html ${curl_session_file}
fi
