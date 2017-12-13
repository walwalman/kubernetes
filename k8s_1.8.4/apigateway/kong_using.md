### kong的使用

添加插件:

>在以下的步骤中，您将通过配置key-auth插件为您的API添加一个认证的功能。在添加此插件之前，您的所有API都被将代理到上游头。添加并配置此插件后，只有具有正确API密钥的请求会被代理 - 所有其他请求将被KONG拒绝，从而保护您的上游服务免受未经授权的使用，从而实现权限认证功能。


##### 为您的API配置 key-auth 插件

通过以下命令，为之前添加的API新增认证功能：

	curl -i -X POST \
	  --url http://localhost:8001/apis/example-api/plugins/ \
	  --data 'name=key-auth'

该插件还接受一个 config.key_names 参数，默认为[apikey]。它表示在一次请求中，应该包含API密钥[apikey]和参数列表，apikey可以放在header中，也可以直接当作一个请求参数来使用



##### 验证

使用以下命令来验证：

	$ curl -i -X GET --url http://localhost:8000/ --header 'Host: example.com'
	HTTP/1.1 401 Unauthorized
	Date: Mon, 04 Dec 2017 10:25:21 GMT
	Content-Type: application/json; charset=utf-8
	Transfer-Encoding: chunked
	Connection: keep-alive
	WWW-Authenticate: Key realm="kong"
	Server: kong/0.11.2
	
	{"message":"No API key found in request"}


正确验证：

	curl -i -X GET --url http://localhost:8000/ --header 'Host: example.com' --header 'apikey=xxx'



### 添加一个用户(Consumer)

	curl -i -X POST \
  	--url http://localhost:8001/consumers/ \
  	--data "username=Jason"

如果想要将用户和已有的其他数据库中的用户进行关联，可通过添加｀custom_id｀参数来实现，其值可以是现存用户的id。


为此用户添加一个[apikey]认证：

　　现在，我们可以通过发出以下请求为我们刚刚创建的用户Jason创建一个密钥

	curl -i -X POST \
	  --url http://localhost:8001/consumers/Jason/key-auth/ \
	  --data 'key=ENTER_KEY_HERE'


验证您的用户的apikey是否有效：

　　我们现在可以发出以下请求，来验证用户Jason的apikey是否有效：

	 curl -i -X GET \
	  --url http://localhost:8000 \
	  --header "Host: example.com" \
	  --header "apikey: ENTER_KEY_HERE"





	