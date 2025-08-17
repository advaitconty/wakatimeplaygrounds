# main wakatime script

import requests
import asyncio

"""
Sample heartbeat: 
{
    entity: {
        type: "heartbeat",
        time: 1234567890,
        category: "coding",
        project: "my_project",
        branch: "main",
        language: "python"
    }
}
"""


async def send_heartbeat(type, time, category, project, branch, language, waka_url):
    