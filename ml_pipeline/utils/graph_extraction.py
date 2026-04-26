import numpy as np
from collections import deque
import torch

def get_neighbors(img, x, y):
    region = img[x-1:x+2, y-1:y+2]
    return np.sum(region) - img[x, y]

def extract_nodes(skel):
    nodes = []
    h, w = skel.shape
    for x in range(1, h-1):
        for y in range(1, w-1):
            if skel[x, y] == 1:
                n = get_neighbors(skel, x, y)
                if n == 1:
                    node_type = "endpoint"
                elif n >= 3:
                    node_type = "junction"
                else:
                    continue
                nodes.append({
                    "id": len(nodes),
                    "type": node_type,
                    "x": x,
                    "y": y
                })
    return nodes

def trace_edge(skel, start, visited):
    path = []
    stack = deque([start])
    while stack:
        x, y = stack.pop()
        if (x, y) in visited:
            continue
        visited.add((x, y))
        path.append((x, y))
        for dx in [-1,0,1]:
            for dy in [-1,0,1]:
                nx, ny = x+dx, y+dy
                if skel[nx, ny] == 1 and (nx, ny) not in visited:
                    stack.append((nx, ny))
    return path

def build_edges(skel, nodes):
    visited = set()
    edges = []
    for node in nodes:
        start = (node["x"], node["y"])
        if start in visited:
            continue
        path = trace_edge(skel, start, visited)
        if len(path) < 2:
            continue
        edges.append({
            "from": node["id"],
            "to": None, # This would need more complex logic to find the exact 'to' node
            "path": path,
            "length": len(path)
        })
    return edges

def graph_to_tensors(nodes, edges):
    node_features = []
    for n in nodes:
        node_features.append([
            n["x"],
            n["y"],
            1.0 if n["type"] == "junction" else 0.0
        ])
    x = torch.tensor(node_features, dtype=torch.float)
    
    edge_index = []
    for e in edges:
        if e["to"] is None:
            continue
        edge_index.append([e["from"], e["to"]])
    
    if len(edge_index) > 0:
        edge_index = torch.tensor(edge_index).t().contiguous()
    else:
        edge_index = torch.zeros((2, 0), dtype=torch.long)
        
    return x, edge_index
