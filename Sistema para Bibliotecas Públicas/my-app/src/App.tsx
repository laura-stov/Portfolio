import React from "react";
import LivroLista from "./components/pages/livro/LivroLista";
import LivroCadastro from "./components/pages/livro/LivroCadastro";
import LivroAlterar from "./components/pages/livro/LivroAlterar";
import AutorAlterar from "./components/pages/autor/AutorAlterar";
import AutorLista from "./components/pages/autor/AutorLista";
import AutorCadastro from "./components/pages/autor/AutorCadastro";
import LeitorAlterar from "./components/pages/leitor/LeitorAlterar";
import LeitorLista from "./components/pages/leitor/LeitorLista";
import LeitorCadastro from "./components/pages/leitor/LeitorCadastro";
import EmprestimoFicha from "./components/pages/emprestimo/EmprestimoFicha";
import EmprestimoLista from "./components/pages/emprestimo/EmprestimoLista";
import EmprestimoAlterar from "./components/pages/emprestimo/EmprestimoAlterar"
import DevolucaoLista from "./components/pages/emprestimo/DevolucaoLista";
import { BrowserRouter, Link, Route, Routes } from "react-router-dom";

function App() {
  return (
    <div id="app">
      <BrowserRouter>
        <nav>
          <ul>
            <li>
              <Link to="/">Home</Link>
            </li>
            <li>
              <Link to="/pages/livro/listar">Listar Livros</Link>
            </li>
            <li>
              <Link to="/pages/livro/cadastrar">Cadastrar Livros</Link>
            </li>
            <li>
              <Link to="/pages/autor/listar">Listar Autores</Link>
            </li>
            <li>
              <Link to="/pages/autor/cadastrar">Cadastrar Autores</Link>
            </li>
            <li>
              <Link to="/pages/leitor/listar">Listar Leitores</Link>
            </li>
            <li>
              <Link to="/pages/leitor/cadastrar">Cadastrar Leitores</Link>
            </li>
            <li>
              <Link to="/pages/emprestimo/ficha">Realizar Empréstimo</Link>
            </li>
            <li>
              <Link to="/pages/emprestimo/listar">Listar Empréstimos</Link>
            </li>
            <li>
              <Link to="/pages/devolucao/listar">Listar Devoluções</Link>
            </li>
          </ul>
        </nav>
        <Routes>
          <Route path="/" element={<LivroLista />} />
          <Route path="/pages/livro/listar" element={<LivroLista />} />
          <Route path="/pages/livro/cadastrar" element={<LivroCadastro />} />
          <Route path="/pages/livro/alterar/:id" element={<LivroAlterar />} />
          <Route path="/pages/autor/listar" element={<AutorLista />} />
          <Route path="/pages/autor/alterar/:id" element={<AutorAlterar />} />
          <Route path="/pages/autor/cadastrar" element={<AutorCadastro />} />
          <Route path="/pages/leitor/listar" element={<LeitorLista />} />
          <Route path="/pages/leitor/alterar/:id" element={<LeitorAlterar />} />
          <Route path="/pages/leitor/cadastrar" element={<LeitorCadastro />} />
          <Route path="/pages/emprestimo/ficha" element={<EmprestimoFicha />} />
          <Route path="/pages/emprestimo/listar" element={<EmprestimoLista />} />
          <Route path="/pages/emprestimo/alterar/:id" element={<EmprestimoAlterar />} />
          <Route path="/pages/devolucao/listar" element={<DevolucaoLista />} />
        </Routes>
      </BrowserRouter>
    </div>
  );
}

export default App;
