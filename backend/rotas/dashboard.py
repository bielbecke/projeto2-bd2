from flask import Blueprint, jsonify

from database.dashboard import DashboardDatabase

dashboard_blueprint = Blueprint("dashboard", __name__)


@dashboard_blueprint.route("/dashboard/resumo", methods=["GET"])
def resumo():
    return jsonify(DashboardDatabase().resumo()), 200


@dashboard_blueprint.route("/dashboard/qtd-por-cidade", methods=["GET"])
def qtd_por_cidade():
    return jsonify(DashboardDatabase().qtd_por_cidade()), 200


@dashboard_blueprint.route("/dashboard/valor-por-cidade", methods=["GET"])
def valor_por_cidade():
    return jsonify(DashboardDatabase().valor_por_cidade()), 200


@dashboard_blueprint.route("/dashboard/top-cidades-valor", methods=["GET"])
def top_cidades_valor():
    return jsonify(DashboardDatabase().top_cidades_valor()), 200


@dashboard_blueprint.route("/dashboard/top-cidades-qtd", methods=["GET"])
def top_cidades_qtd():
    return jsonify(DashboardDatabase().top_cidades_qtd()), 200


@dashboard_blueprint.route("/dashboard/top-empresas-qtd", methods=["GET"])
def top_empresas_qtd():
    return jsonify(DashboardDatabase().top_empresas_qtd()), 200


@dashboard_blueprint.route("/dashboard/top-empresas-valor", methods=["GET"])
def top_empresas_valor():
    return jsonify(DashboardDatabase().top_empresas_valor()), 200
