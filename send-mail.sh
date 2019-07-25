#!/bin/bash
#
######################################################################
#
# [スクリプト名]
#  send-mail.sh
#
# [処理概要]
#  Oracle Functionsを使用したメール送信
#  1.メール送信関数(Oracle Functions)に渡すjsonファイル作成
#  2.ファンクションを実行しメール送信
#
# [引数]
#  1.送信先アドレス
#
# [関連ファイル]
#  ./send-mail.txt (メール本文記載ファイル)
#
######################################################################
# バージョン 作成／更新者   更新日      変更内容
#---------------------------------------------------------------------
# 001-01     yu araki       2013/12/07  新規作成
#
######################################################################
######################################################################
# 事前処理
######################################################################
#---------------------------------------------------------------------
# 変数、定数定義
#---------------------------------------------------------------------
## 作業用変数
# タイムスタンプ
NOW=`date "+%Y-%m-%d %H:%M:%S"`
# 日付
TODAY=`date "+%Y%m%d"`
# 作業ディレクトリ
WORK_DIR="$(dirname $0)/"
# このスクリプト名
SCRIPT_NAME=$(basename $0)
# ログディレクトリ
LOG_DIR="${WORK_DIR}log/"
# スクリプトログ
SCRIPT_LOG="${LOG_DIR}${TODAY}.send-mail.script.log"
# エラーログ
ERROR_LOG="${LOG_DIR}${TODAY}.send-mail.error.log"

## 引数
# 引数1.送信先アドレス
TO="$1"

## OracleFunctionsのメール送信関連
# メール本文ファイル
MAIL_FILE="send-mail.txt"
# メール本文ファイルパス
MAIL_DIR="${WORK_DIR}${MAIL_FILE}"
# 一時作成jsonファイル名
TMP_JSON="tmp.json"
# 一時作成jsonファイルパス
TMP_JSON_DIR="${WORK_DIR}${TMP_JSON}"
# メール件名
SUBJECT="Urgent! ORA Error detection of XXX job"
# メール本文をjson用に変換　※実際は一つ下を使用
BODY=$(cat ${MAIL_DIR} | sed -e 's/$/\\'\n'/g' | tr -d '\r' | tr -d '\n' | sed -e "s/%HOSTNAME%/$(hostname)/")
# メール本文をjson用に変換　(%JOBNAME%,%ERRORCODE%に値を入れられるようsed等で変換する。)
#BODY=$(cat send-mail.txt | sed -e 's/$/\\'\n'/g' | tr -d '\r' | tr -d '\n' | sed -e "s/%HOSTNAME%/$(hostname)/" -e "s/%JOBNAME%/$(grep xxx)/" -e "s/%ERRORCODE%/$(grep "ora-" /xxx/xxx/xxx.log)/")

## スクリプト失敗通知関連
# メール件名
FAIL_SUBJECT="Script execution failed"

######################################################################
# 共通処理
######################################################################
#---------------------------------------------------------------------
# スクリプト終了時自動実行処理
# ・一時ファイル(tmp.json)削除
# ・事後処理終了ログ出力
#---------------------------------------------------------------------
trap fnc_trap_process 0

######################################################################
# 関数定義
######################################################################
#---------------------------------------------------------------------
# ログ出力関数
#---------------------------------------------------------------------
function fnc_output_scriptlog() {
  (echo "$SCRIPT_NAME: $1 $NOW" >>$SCRIPT_LOG) 2>/dev/null
  return $?
}
#---------------------------------------------------------------------
# スクリプト失敗通知関数
#---------------------------------------------------------------------
function fnc_alert_mail() {
  echo -e "$1 \n\nfilename: $SCRIPT_NAME" | mail -s "$FAIL_SUBJECT" $TO
  return $?
}

#---------------------------------------------------------------------
# スクリプト終了時自動実行関数
#---------------------------------------------------------------------
function fnc_trap_process() {

  ## 一時ファイル削除
  [[ "$TMP_JSON_DIR" ]] && rm -rf $TMP_JSON_DIR

  # 事後処理終了メッセージ出力
  fnc_output_scriptlog "The temporary file ${TMP_JSON_DIR} has been deleted."

  exit 0
}

######################################################################
# メイン処理
######################################################################
#---------------------------------------------------------------------
# 1.メール送信関数(Oracle Functions)に渡すjsonファイル作成
#---------------------------------------------------------------------
# 開始ログ出力
fnc_output_scriptlog "[Start] Start send-mail.sh process."

# ログディレクトリ確認
mkdir -p ${LOG_DIR}

# 作業ディレクトリ移動
cd ${WORK_DIR}

# メール送信用jsonファイル作成
cat <<EOF > ${TMP_JSON_DIR}
{
    "To": "$TO",
    "Subject": "$SUBJECT",
    "Body": "$BODY"
}
EOF

# 成否確認
if [ "$?" = "0" ];then
  fnc_output_scriptlog  "Succeeded in creating json file."
else
  # エラー通知
  for i in fnc_output_scriptlog fnc_alert_mail; do ${i} "Failed to create json file."; done
  # エラー終了
  exit 1
fi

#---------------------------------------------------------------------
# 2.ファンクションを実行しメール送信
#---------------------------------------------------------------------
# jsonファイルを渡しメール送信ファンクション実行
cat ${TMP_JSON_DIR} | fn invoke fn-email-app sendemail 2>> $ERROR_LOG

# 成否確認
if [ "$?" = "0" ];then
  fnc_output_scriptlog  "Succeeded in sending mail using Oracle FUnctions."
else
  # エラー通知
  for i in fnc_output_scriptlog fnc_alert_mail; do ${i} "Failed to send mail using Oracle FUnctions."; done
  # エラー終了
  exit 1
fi

######################################################################
# 終了処理
######################################################################
# 終了ログ出力
fnc_output_scriptlog "[End] send-mail.sh process is complete."

exit 0
