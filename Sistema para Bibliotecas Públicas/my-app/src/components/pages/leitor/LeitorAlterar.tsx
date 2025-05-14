import axios from "axios";
import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Leitor } from "../../../models/Leitor";

function LeitorAlterar(){
    const { id } = useParams();
    const [nome, setNome] = useState("");
    const [sobrenome, setSobrenome] = useState("");
    const [telefone, setTelefone] = useState("");
    const [email, setEmail] = useState("");
    const [cpf, setCPF] = useState("");

    const navigate = useNavigate();

    useEffect(() => {
        if(id) {
            axios
                .get<Leitor>(`http://localhost:5274/biblioteca/leitor/buscar/${id}`)
                .then((resposta) => {
                    setNome(resposta.data.nome);
                    setSobrenome(resposta.data.sobrenome);
                    setTelefone(resposta.data.telefone);
                    setEmail(resposta.data.email);
                    setCPF(resposta.data.cpf);
                })
                .catch((error) => {
                    console.error("Erro ao buscar dados:", error);
                });
        }
    }, [id]);

    function enviarLeitor(e: any) {
        e.preventDefault();

        const leitor : Leitor = {
            nome: nome,
            sobrenome: sobrenome,
            telefone: telefone,
            email: email,
            cpf: cpf,
        };

        axios
            .put(`http://localhost:5274/biblioteca/leitor/alterar/${id}`, leitor)
            .then(() => {
                console.log("Leitor alterado com sucesso");
                navigate("/pages/leitor/listar");
            })
            .catch((error) => {
                console.error("Erro ao alterar leitor:", error);
            });
    }

    // Função para garantir que o CPF tenha apenas números
    function handleCPFChange(e: any) {
        const cpfValue = e.target.value;
        const onlyNumbers = cpfValue.replace(/\D/g, ''); // Remove tudo que não for número
        setCPF(onlyNumbers);
    }

    return (
        <div id="alterar_leitor" className="container">
            <h1>Alterar Leitor</h1>
            <form onSubmit={enviarLeitor}>
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
                    <label htmlFor="telefone">Telefone</label>
                    <input 
                        type="text" 
                        name="telefone" 
                        id="telefone"
                        value={telefone}
                        required
                        onChange={(e: any) => setTelefone(e.target.value)} 
                    />
                </div>

                <div>
                    <label htmlFor="email">Email</label>
                    <input 
                        type="email" 
                        name="email" 
                        id="email"
                        value={email}
                        required
                        onChange={(e: any) => setEmail(e.target.value)} 
                    />
                </div>

                <div>
                    <label htmlFor="cpf">CPF</label>
                    <input 
                        type="text" 
                        name="cpf" 
                        id="cpf"
                        value={cpf}
                        required
                        onChange={handleCPFChange}
                        maxLength={11} 
                    />
                </div>

                <button type="submit">Alterar Leitor</button>
            </form>
        </div>
    );
}

export default LeitorAlterar;