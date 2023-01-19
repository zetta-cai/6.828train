[manual](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/user-manual.html)
[ref](https://eagain.net/articles/git-for-computer-scientists/) 

* blob：最简单的对象，只是一堆字节。这通常是一个文件，但可以是符号链接或其他任何东西。指向的对象决定语义。
* tree：目录由对象表示。它们指的是包含文件内容的（文件名、访问模式等都存储在中），以及其他子目录。
* refs：引用，或头部或分支，就像贴在DAG节点上的便利贴。当DAG只被添加到现有节点而不能被变异时，帖子可以自由移动。它们不会存储在历史记录中，也不会在存储库之间直接传输。它们就像书签，“我在这里工作”。
* gitcommit向DAG添加一个节点，并将当前分支的post-it注释移动到此新节点。
  
![git-storage](/pic/gitstudy/git-storage.svg)

1. 这是最简单的存储库。我们有一个远程存储库，其中有一个提交。 

![g2](/pic/gitstudy/git-history.2.dot.svg)

1.  之后的情况。由于合并是一个（也就是说，我们的本地分支中没有新的提交），所以唯一发生的事情就是移动便利贴并分别更改工作目录中的文件。

git merge remotes/MYSERVER/master fastforward \
![g3](/pic/gitstudy/git-history.3.dot.svg)

3. 我们既有新的本地提交，也有新的远程提交。显然，需要合并。

git commitgit fetch \
![g4](/pic/gitstudy/git-history.4.dot.svg)

4. 因为我们有新的本地提交，所以这是在 DAG 中创建了一个实际的新节点。 注意它有两个父母。

git merge remotes/MYSERVER/masterfast forwardcommit commit \
git commitgit fetch \
![g5](/pic/gitstudy/git-history.5.dot.svg)

5. 这是树在两个分支上进行几次提交和另一个合并后将要处理的内容。 看到“拼接”图案出现了吗？ DAG 准确记录了所采取行动的历史

![g6](/pic/gitstudy/git-history.6.dot.svg)

6. “拼接”模式读起来有些乏味。 如果您还没有发布您的分支，或者已经明确表示其他人不应该将他们的工作建立在它的基础上，那么您还有一个选择。 你可以在你的分支上，而不是合并，你的提交被另一个具有不同父级的提交所取代，你的分支被移动到那里。(rebase) \
您的旧提交将保留在 DAG 中，直到垃圾被收集为止。 暂时忽略它们，但要知道如果你完全搞砸了，还有一条出路。 如果您有额外的便利贴指向您的旧提交，它们将继续指向它，并使您的旧提交无限期地保持活动状态。 不过，这可能相当令人困惑。\
不要rebase 其他人在其上创建新提交的分支。 有可能从中恢复，这并不难，但所需的额外工作可能令人沮丧 

![g7](/pic/gitstudy/git-history.7.dot.svg)

7. 垃圾收集（或忽略无法访问的提交）并在 d 分支之上创建新提交后的情况

![g8](/pic/gitstudy/git-history.8.dot.svg)

8. rebase 还知道如何使用一个命令对多个提交进行变基。

![g9](/pic/gitstudy/git-history.9.dot.svg)