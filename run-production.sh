#!/bin/bash
# ローカルテスト環境用スクリプト - ポート30000でFlutterアプリを起動
# 使用法: ./run-local-test.sh

echo "ローカルテスト環境でのFlutter Web アプリを起動します..."
echo "ポート: 30000"
echo "ブラウザで http://localhost:30000 にアクセスしてください"
echo ""

flutter run -d chrome --web-port 30000
