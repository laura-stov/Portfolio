import { Autor } from "./Autor";
import { Leitor } from "./Leitor";
import { Livro } from "./Livro";

export interface Emprestimo {
    emprestimoId: string;
    dataEmprestimo: string;
    prazoDevolucao: string;
    dataDevolucao: string;
    ativo: boolean;
    livroId: string;
    autorId: string;
    leitorId: string;
    autor: Autor;
    leitor: Leitor;
    livro: Livro;
}
