import axios from "axios";
import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Autor } from "../../../models/Autor";

function AutorAlterar(){
    const { id } = useParams();
    const [nome, setNome] = useState("");
    const [sobrenome, setSobrenome] = useState("");
    const [pais, setPais] = useState("");
    const navigate = useNavigate();

    useEffect(() => {
        if(id) {
            axios
                .get<Autor>(`http://localhost:5274/biblioteca/autor/buscar/${id}`)
                .then((resposta) => {
                    setNome(resposta.data.nome);
                    setSobrenome(resposta.data.sobrenome);
                    setPais(resposta.data.pais);
                })
                .catch((error) => {
                    console.error("Erro ao buscar dados:", error);
                });
        }
    }, [id]);

    function enviarAutor(e: any) {
        e.preventDefault();

        const autor : Autor = {
            nome: nome,
            sobrenome: sobrenome,
            pais: pais,
        };

        // Atualizar o empréstimo
        axios
            .put(`http://localhost:5274/biblioteca/autor/alterar/${id}`, autor, {
                headers: {
                    "Content-Type": "application/json",
                },
            })
            .then(() => {
                console.log("Empréstimo alterado com sucesso");
                navigate("/pages/autor/listar");
            })
            .catch((error) => {
                console.error("Erro ao alterar empréstimo:", error);
            });
    }

    return (
        <div id="alterar_autor" className="container">
            <h1>Alterar Autor</h1>
            <form onSubmit={enviarAutor}>
                <div>
                    <label htmlFor="nome">Nome</label>
                    <input 
                        type="text" 
                        id="nome" 
                        name="nome" 
                        value={nome} 
                        required
                        onChange={(e: any) => setNome(e.target.value)}
                    />
                </div>

                <div>
                    <label htmlFor="sobrenome">Sobrenome</label>
                    <input 
                        type="text" 
                        name="sobrenome" 
                        id="sobrenome"
                        value={sobrenome}
                        required
                        onChange={(e: any) => setSobrenome(e.target.value)} 
                    />
                </div>

                <div>
                    <label htmlFor="pais">País</label>
                    <input 
                        type="text" 
                        name="pais" 
                        id="pais"
                        value={pais}
                        required
                        onChange={(e: any) => setPais(e.target.value)} 
                    />
                </div>

                <button type="submit">Alterar Autor</button>
            </form>
        </div>
    );
}

export default AutorAlterar;