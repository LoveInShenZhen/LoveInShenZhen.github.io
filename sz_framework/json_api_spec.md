## sz-json api 规范 
---
* SZ 是一套基于 **前后端分离** 的思想, 专门用于 后端 (业务,应用服务器)的 快速开发框架.
* 前端静态HTML页面是通过 **ajax** 的方式, 调用后端提供的 **http api** 接口
* sz 框架定义了一套 **http json api** 的规范

### Request-Response 形式
* **Http Request**, 支持 **GET**, **POST**, **HEAD** 这三种方式
* Response 返回一个Json文本
* Response 的 **Content-Type** : **application/json; charset=utf-8**
* Response 的 **transfer-encoding** : **chunked**

### Response 的 Json 格式
* 所有的Response都包括如下的2个基础字段:
```json
{
    "ret": 0,
    "errmsg": "OK",
}
```

> - **ret** : 0 表示成功, 其他值表示错误码, 由开发人员自己定义. 
> - **errmsg** : 当ret=0时, 返回OK, 非0时, 返回错误描述信息. 例如: token超时; 违背某某业务规则; 某某参数为空 等等
> - 这2个基础字段, 是从 **ReplyBase** 类继承而来的. 
> - web前端程序, 需要对调用返回的 **ret** 值进行判断, 进行相应的错误处理


### **UTF-8** 字符编码
* Request 和 Response 的字符编码要求是: charset=utf-8

### GET 方式

?> _TODO_

### POST Form 方式

?> _TODO_

### POST Json 方式

?> _TODO_

### HEAD 方式

### 参考