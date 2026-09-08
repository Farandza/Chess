from collections import defaultdict
from fastapi import WebSocket
class GameHub:
    def __init__(self):
        self.connections=defaultdict(set);self.users={};self.presence_users={}
    def online(self,user_id:int):
        return (any(uid == user_id for _,uid in self.users.values()) or
                any(uid == user_id for uid in self.presence_users.values()))
    async def connect(self,game_id:int,user_id:int,ws:WebSocket):
        await ws.accept();self.connections[game_id].add(ws);self.users[ws]=(game_id,user_id)
        await self.broadcast_presence(user_id)
    async def disconnect(self,game_id:int,ws:WebSocket):
        item=self.users.pop(ws,None);self.connections[game_id].discard(ws)
        if item: await self.broadcast_presence(item[1])
    async def connect_presence(self,user_id:int,ws:WebSocket):
        await ws.accept();self.presence_users[ws]=user_id;await self.broadcast_presence(user_id)
    async def disconnect_presence(self,ws:WebSocket):
        user_id=self.presence_users.pop(ws,None)
        if user_id is not None: await self.broadcast_presence(user_id)
    async def broadcast_presence(self,user_id:int):
        event={'type':'presence','user_id':user_id,'is_online':self.online(user_id)}
        for ws in list(self.presence_users):
            try: await ws.send_json(event)
            except Exception: self.presence_users.pop(ws,None)
    async def broadcast(self,game_id:int,event:dict):
        for ws in list(self.connections[game_id]):
            try: await ws.send_json(event)
            except Exception: await self.disconnect(game_id,ws)
hub=GameHub()
