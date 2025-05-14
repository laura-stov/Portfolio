import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import axios from "axios";
import { Autor } from "../../../models/Autor";

function AutorLista() {
    const [autores, setAutores] = useState<Autor[]>([]);

    useEffect(() => {
        fetch("http://localhost:5274/biblioteca/autor/listar", {
            method: 'GET', 
        })
            .then((resposta) => {
                if (!resposta.ok) {
                    throw new Error(`Erro na API: ${resposta.status}`);
                }
                return resposta.json(); // Lê diretamente como JSON
            })
            .then((data) => {
                setAutores(data || []); // Define lista de autores ou um array vazio
            })
            .catch((error) => {
                console.error("Erro ao buscar autores:", error);
                setAutores([]); // Garante um estado seguro
            });
    }, []);

    function deletar(id: string) {
        axios
            .delete(`http://localhost:5274/biblioteca/autor/deletar/${id}`)
            .then(() => {
                console.log("Autor deletado com sucesso!");
                window.location.reload();
            });
    }

    return (
        <div className="container">
            <h1>Lista de Autores</h1>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Nome</th>
                        <th>Sobrenome</th>
                        <th>País</th>
                        <th>Deletar</th>
                        <th>Alterar</th>
                    </tr>
                </thead>
                <tbody>
                    {autores.length > 0 ? (
                        (autores.map((autor) => (
                            <tr key={autor.autorId}>
                                <td>{autor.autorId}</td>
                                <td>{autor.nome}</td>
                                <td>{autor.sobrenome}</td>
                                <td>{autor.pais}</td>
                                <td>
                                    <button onClick={() => deletar(autor.autorId!)}>Deletar</button>
                                </td>
                                <td>
                                    <Link to={`/pages/autor/alterar/${autor.autorId}`}>Alterar</Link>
                                </td>
                            </tr>
                        )))
                    ): (
                        <tr>
                            <td colSpan={6}>Nenhum autor encontrado.</td>
                        </tr>
                    )}
                </tbody>
            </table>
        </div>
    );
}

export default AutorLista;
