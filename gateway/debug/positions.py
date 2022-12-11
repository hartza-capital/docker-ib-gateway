import ib_insync as ibis

ibclient = ibis.IB()
client = ibclient.connect(
                host="127.0.0.1", 
                port=4001,
                clientId=200,
                readonly=True
            )

positions = client.accountSummary()
print(positions)
