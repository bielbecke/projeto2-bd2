from flask import Flask, jsonify
from flask_cors import CORS

from rotas.cidades import cidades_blueprint
from rotas.empresas import empresas_blueprint
from rotas.servicos import servicos_blueprint
from rotas.clientes import clientes_blueprint
from rotas.funcionarios import funcionarios_blueprint
from rotas.pedidos import pedidos_blueprint
from rotas.dashboard import dashboard_blueprint

app = Flask(__name__)

# libera o frontend (React/Vite, em outra porta) a chamar essa API
CORS(app)


@app.route("/", methods=["GET"])
def raiz():
    return jsonify({"status": "ok"}), 200


app.register_blueprint(cidades_blueprint)
app.register_blueprint(empresas_blueprint)
app.register_blueprint(servicos_blueprint)
app.register_blueprint(clientes_blueprint)
app.register_blueprint(funcionarios_blueprint)
app.register_blueprint(pedidos_blueprint)
app.register_blueprint(dashboard_blueprint)


if __name__ == "__main__":
    app.run("0.0.0.0", port=8000, debug=True)
