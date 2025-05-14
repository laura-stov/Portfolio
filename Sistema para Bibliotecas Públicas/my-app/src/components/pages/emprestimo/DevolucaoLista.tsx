import { useEffect, useState } from "react";
import { Emprestimo } from "../../../models/Emprestimo";

function DevolucaoLista() {
    const [emprestimos, setEmprestimos] = useState<Emprestimo[]>([]);

    useEffect(() => {
        fetch("http://localhost:5274/biblioteca/devolucao/listar", {
            method: 'GET', 
        })
            .then((resposta) => {
                if (!resposta.ok) {
                    throw new Error(`Erro na API: ${resposta.status}`);
                }
                return resposta.text(); // Lê como texto para evitar erro de JSON
            })
            .then((data) => {
                if (data) {
                    setEmprestimos(JSON.parse(data)); // Processa somente se não estiver vazio
                } else {
                    setEmprestimos([]); // Define lista vazia se o corpo for vazio
                }
            })
            .catch((error) => {
                console.error("Erro ao buscar devoluções:", error);
            });
    }, []);

    // Função para formatar data e hora
    const formatarDataHora = (data: string) => {
        const dataObj = new Date(data);
        return dataObj.toLocaleString('pt-BR', {
            weekday: 'short',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
        });
    };
    
    return (
        <div className="container">
            <h1>Lista de Devoluções</h1>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Leitor</th>
                        <th>CPF do Leitor</th>
                        <th>Livro</th>
                        <th>Autor</th>
                        <th>Data Empréstimo</th>
                        <th>Prazo Devolução</th>
                        <th>Data da Devolução</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    {emprestimos.length > 0 ? (
                        emprestimos.map((emprestimo) => (
                            <tr key={emprestimo.emprestimoId}>
                                <td>{emprestimo.emprestimoId}</td>
                                <td>{emprestimo.leitor.nome + ' ' + emprestimo.leitor.sobrenome}</td>
                                <td>{emprestimo.leitor.cpf}</td>
                                <td>{emprestimo.livro.titulo}</td>
                                <td>{emprestimo.livro.autor?.nome + ' ' + emprestimo.livro.autor?.sobrenome}</td>
                                <td>{formatarDataHora(emprestimo.dataEmprestimo)}</td>
                                <td>{formatarDataHora(emprestimo.prazoDevolucao)}</td>
                                <td>{formatarDataHora(emprestimo.dataDevolucao)}</td>
                                <td>{emprestimo.ativo ? "Ativo" : "Devolvido"}</td>
                            </tr>
                        ))
                    ) : (
                        <tr>
                            <td colSpan={9}>Nenhuma devolução encontrada.</td>
                        </tr>
                    )}
                </tbody>
            </table>
        </div>
    );
}

export default DevolucaoLista;