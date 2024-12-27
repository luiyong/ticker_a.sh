#!/bin/bash
# 设置编码环境变量，避免编码相关问题（可根据实际情况调整编码设置方式）
export LC_ALL=C

# 定义函数来获取股票实时数据
tickprice() {
    local code="$1"
    local url="http://qt.gtimg.cn/q=$code,money.api"
    local response=$(curl -s "$url")  # 使用curl获取接口返回的数据，-s表示静默模式，不显示进度信息

    if [ -z "$response" ]; then
        echo "获取股票数据失败，请检查网络连接或股票代码是否正确。"
        return 1
    fi

    # 提取等号后面的实际数据内容
    local data=$(echo "$response" | cut -d '=' -f 2 | tr '~' '\n')
    local symbol=$(echo "$code" | cut -d '.' -f 2)  # 获取股票代码部分（假设传入格式类似sh600519这种，提取出600519）
    local name=$(echo "$data" | sed -n '2p')  # 股票名称，取第二行
    # 将数据转换为UTF-8编码（假设你的系统默认支持UTF-8编码较好处理，可根据实际情况调整编码格式）
    local name_utf8=$(echo "$name" | iconv -f GBK -t UTF-8 2>/dev/null)
    if [ -z "$name_utf8" ]; then
        echo "数据编码转换失败，请检查数据编码情况。"
        return 1
    fi

    local last=$(echo "$data" | sed -n '4p')  # 当前价格，取第四行
    local open=$(echo "$data" | sed -n '6p')  # 今日开盘价，取第五行
    local yesterday_close=$(echo "$data" | sed -n '5p')  # 昨日收盘价，取第15行
    # 涨跌点数（涨跌幅度），直接提取对应行的数据，去除可能多余的空格等字符
    local updown=$(echo "$data" | sed -n '32p')
    # 涨跌百分比，按照正确的计算公式进行计算，先计算差值，再除以昨日收盘价并乘以100，保留两位小数
    local percent=$(echo "$data" | sed -n '33p')
    local high=$(echo "$data" | sed -n '34p')  # 今日最高价
    local low=$(echo "$data" | sed -n '35p')  # 今日最低价
    local transactions=$(echo "$data" | sed -n '36p' | cut -d '/' -f 2)  # 成交数量，取第八行
    local turnover=$(echo "$data" | sed -n '36p' | cut -d '/' -f 3)  # 成交金额，取第17行

    # 使用printf格式化输出，形成表格的一行数据，各字段间用制表符\t分隔，方便对齐
    printf "%-10s\t%-15s\t%-10s\t%-10s\t%-10s\t%-10s\t%-10s\t%-10s\t%-10s\n" \
           "$symbol" "$name_utf8" "$last" "$open" "$yesterday_close" "$updown" "$percent%" "$high" "$low"
}

# 主程序部分，获取脚本传入的股票代码参数
if [ $# -eq 0 ]; then
    echo "请至少传入一个股票代码作为参数（例如：./script.sh sh600036 sh600519)"
    exit 1
fi

# 先输出表头，同样使用printf格式化输出，设置好各列标题的宽度和对齐方式
printf "%-10s\t%-15s\t%-10s\t%-10s\t%-10s\t%-10s\t%-10s\t%-10s\t%-10s\n" \
       "code" "name" "last" "open" "yesterday_close" "updown" "percent" "high" "low"


# 循环遍历传入的股票代码参数，调用tickprice函数获取每个股票的行情信息并展示
for code in "$@"; do
    tickprice "$code"
done


#http://qt.gtimg.cn/q=sz002142,money.api
