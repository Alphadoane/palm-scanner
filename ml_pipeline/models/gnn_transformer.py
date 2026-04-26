import torch
import torch.nn as nn
import torch.nn.functional as F

# --- GRAPH NEURAL NETWORK ---
class GATLayer(nn.Module):
    def __init__(self, in_dim, out_dim):
        super().__init__()
        self.W = nn.Linear(in_dim, out_dim)
        self.a = nn.Linear(2*out_dim, 1)

    def forward(self, x, edge_index):
        h = self.W(x)
        row, col = edge_index
        a_input = torch.cat([h[row], h[col]], dim=1)
        e = F.leaky_relu(self.a(a_input))
        attention = torch.softmax(e, dim=0)
        
        out = torch.zeros_like(h)
        for i in range(len(row)):
            out[row[i]] += attention[i] * h[col[i]]
        return out

class PalmGNN(nn.Module):
    def __init__(self):
        super().__init__()
        self.gat1 = GATLayer(3, 16)
        self.gat2 = GATLayer(16, 32)
        self.classifier = nn.Linear(32, 8)

    def forward(self, x, edge_index):
        x = F.relu(self.gat1(x, edge_index))
        x = F.relu(self.gat2(x, edge_index))
        return self.classifier(x)

# --- GRAPH-TO-TEXT TRANSFORMER ---
def global_pool(node_embeddings):
    mean_pool = torch.mean(node_embeddings, dim=0)
    max_pool = torch.max(node_embeddings, dim=0)[0]
    return torch.cat([mean_pool, max_pool], dim=-1)

class GraphEncoder(nn.Module):
    def __init__(self, input_dim, d_model):
        super().__init__()
        self.proj = nn.Linear(input_dim, d_model)

    def forward(self, graph_embedding):
        return self.proj(graph_embedding)

class PalmInterpreter(nn.Module):
    def __init__(self, d_model=256, vocab_size=10000):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, d_model)
        self.transformer = nn.TransformerDecoder(
            nn.TransformerDecoderLayer(
                d_model=d_model,
                nhead=8,
                dim_feedforward=512
            ),
            num_layers=4
        )
        self.output = nn.Linear(d_model, vocab_size)

    def forward(self, tgt, memory):
        tgt_emb = self.embedding(tgt)
        out = self.transformer(
            tgt=tgt_emb,
            memory=memory.unsqueeze(0)
        )
        return self.output(out)

class GraphToTextModel(nn.Module):
    def __init__(self, gnn, d_model=256):
        super().__init__()
        self.gnn = gnn
        self.pool = global_pool
        self.encoder = GraphEncoder(32, d_model)
        self.decoder = PalmInterpreter(d_model=d_model)

    def forward(self, node_embeddings, edge_index, tgt_tokens):
        node_emb = self.gnn(node_embeddings, edge_index)
        graph_emb = self.pool(node_emb)
        memory = self.encoder(graph_emb)
        return self.decoder(tgt_tokens, memory)
