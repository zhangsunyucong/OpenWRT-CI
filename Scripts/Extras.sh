#!/bin/bash

#增加主题
echo "CONFIG_PACKAGE_luci-theme-$OWRT_THEME=y" >> .config
echo "CONFIG_PACKAGE_luci-app-$OWRT_THEME-config=y" >> .config

#根据源码来修改
if [[ $OWRT_URL != *"lede"* ]] ; then
  #增加luci界面
  echo "CONFIG_PACKAGE_luci=y" >> .config
  echo "CONFIG_LUCI_LANG_zh_Hans=y" >> .config
fi

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	HP_PATCH="../homeproxy/root/etc/homeproxy/resources"

	UPDATE_RESOURCES() {
		local res_type=$1
		local res_repo=$2
		local res_branch=$3
		local res_file=$4
		local res_depth=${5:-1}

		git clone --depth=$res_depth --single-branch --branch $res_branch "https://github.com/$res_repo.git" ./$res_type/

		cd ./$res_type/

		if [[ "${res_file##*.}" == "txt" ]]; then
			echo $(git log -1 --pretty=format:'%s' -- $res_file | grep -o "[0-9]*") > "$res_type.ver"
			mv -f $res_file "$res_type.${res_file##*.}"
		elif [[ "${res_file##*.}" == "zip" ]]; then
			echo $(git log -1 --pretty=format:'%s' | cut -d ' ' -f 1) > "$res_type.ver"
			curl -sfL -O "https://github.com/$res_repo/archive/$res_file"
			mv -f $res_file $HP_PATCH/"${res_repo//\//_}.${res_file##*.}"
		elif [[ "${res_file##*.}" == "db" ]]; then
			local res_ver=$(git tag | tail -n 1)
			echo $res_ver > "$res_type.ver"
			curl -sfL -O "https://github.com/$res_repo/releases/download/$res_ver/$res_file"
		fi

		cp -f $res_type.* $HP_PATCH/

		cd .. && rm -rf ./$res_type/
	}

	UPDATE_RESOURCES "china_ip4" "1715173329/IPCIDR-CHINA" "master" "ipv4.txt" "5"
	UPDATE_RESOURCES "china_ip6" "1715173329/IPCIDR-CHINA" "master" "ipv6.txt" "5"
	UPDATE_RESOURCES "gfw_list" "Loyalsoldier/v2ray-rules-dat" "release" "gfw.txt"
	UPDATE_RESOURCES "china_list" "Loyalsoldier/v2ray-rules-dat" "release" "direct-list.txt"
	UPDATE_RESOURCES "geoip" "1715173329/sing-geoip" "master" "geoip.db"
	UPDATE_RESOURCES "geosite" "1715173329/sing-geosite" "master" "geosite.db"
	UPDATE_RESOURCES "clash_dashboard" "MetaCubeX/metacubexd" "gh-pages" "gh-pages.zip"
fi
