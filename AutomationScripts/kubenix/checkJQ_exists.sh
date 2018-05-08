##CHeck jq exists in linux or not.. If not exists run the following commands
checkJq=$(which jq | wc -l)
if [ $checkJq -eq 0 ]
then
        wget http://stedolan.github.io/jq/download/linux64/jq
        chmod +x ./jq
        sudo cp jq /usr/bin
fi