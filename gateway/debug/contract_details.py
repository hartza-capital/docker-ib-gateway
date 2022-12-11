import ib_insync as ibis

ibclient = ibis.IB()
client = ibclient.connect(
                host="127.0.0.1", 
                port=4001,
                clientId=200,
                readonly=True
            )

stock = ibis.Stock("AAPL", "SMART", currency="USD")

reqData = client.reqContractDetails(stock)
print(reqData)