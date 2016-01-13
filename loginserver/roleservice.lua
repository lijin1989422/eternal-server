local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local message = require "message"

msgpack = require("msgpack.core")

local CMD = {}
local protobuf = {}

local function processRoleListRequest(msg)
	print("---process role list---")
	local data = protobuf.decode("CMsgRoleListRequest", msg)
	local accountid = data.accountid
	print("---account:", accountid)

	local roles = {}
	local sql = "select * from tb_role where accountid = '" .. accountid .. "'"
	local ok, result = pcall(skynet.call, "dbservice", "lua", "query", sql)
	if ok then
		for key,value in pairs(result) do
			local role = {}
			role.id = value["id"]
			role.nickname = value["nickname"]
			role.level = value["level"]
			role.roletype = value["roletype"]
			table.insert(roles, role)
		end
	else
		print("---query error---")
	end

	local tb = {}
	tb.roles = roles
	local msgbody = protobuf.encode("CMsgRoleListResponse", tb)
	return msgpack.pack(message.MSG_ROLE_LIST_RESPONSE_S2C, msgbody)
end

local function processRoleCreateRequest(msg)
	print("---process role create---")
	local data = protobuf.decode("CMsgRoleCreateRequest", msg)
	local accountid = data.accountid
	local nickname = data.nickname
	local roletype = data.roletype
	print("---nickname:", nickname)

	local tb = {}
	local id = os.time()
	local role = {}
	local sql = "insert into tb_role(id, accountid, nickname, roletype) values ('"..id.."','"..accountid.."','"..nickname.."','"..roletype.."')"
	local ok, result = pcall(skynet.call, "dbservice", "lua", "query", sql)
	if ok then
		role.id = id
		role.nickname = nickname
		role.roletype = roletype
		role.level = 1
	else
		print("---query error---")
	end

	tb.role = role
	local msgbody = protobuf.encode("CMsgRoleCreateResponse", tb)
	return msgpack.pack(message.MSG_ROLE_CREATE_RESPONSE_S2C, msgbody)
end

function CMD.dispatch(opcode, msg)
	print("role dispatch msgno " .. opcode)
	if opcode == message.MSG_ROLE_LIST_REQUEST_C2S & 0x0000FFFF then
		return processRoleListRequest(msg)	
	elseif opcode == message.MSG_ROLE_CREATE_REQUEST_C2S & 0x0000FFFF then
		return processRoleCreateRequest(msg)
	end
end

skynet.start(function()
	print("---start login server---")
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(...)))
	end)
	
	protobuf = require "protobuf"
	local login_data = io.open("../proto/role_message.pb", "rb")
	local buffer = login_data:read "*a"
	login_data:close()
	protobuf.register(buffer)

	skynet.register "roleservice"
end)
