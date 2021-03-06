#' Summarize the moderated mediation
#' @param fit An object of class lavaan
#' @param mod name of moderator
#' @param values Optional. Numeric vector
#' @param boot.ci.type Type of bootstrapping interval. Choices are c("norm","basic","perc",bca.simple")
#' @importFrom lavaan parameterEstimates
#' @export
#' @return A data.frame and an object of class modmedSummary
modmedSummary=function(fit,mod="skeptic",values=NULL,boot.ci.type="bca.simple"){

     # boot.ci.type="bca.simple";mod="skeptic";values=NULL
      # fit=semfit;mod="HBP";values=NULL;boot.ci.type="bca.simple"
    res=parameterEstimates(fit,boot.ci.type = boot.ci.type,
                           level = .95, ci = TRUE,
                           standardized = FALSE)
    res=res[res$label!="",]
    res
    if(is.null(values)){
      # values1=res$est[res$label==paste0(mod,".mean")]+c(0,-1,1)*sqrt(res$est[res$label==paste0(mod,".var")])
      values1=extractRange(res,mod=mod)
      values1
    } else{
        values1=values
    }
    select=c("indirect","indirect.below","indirect.above")
    indirect=res$est[which(res$lhs %in% select)]
    lower=res$ci.lower[which(res$lhs %in% select)]
    upper=res$ci.upper[which(res$lhs %in% select)]
    indirectp=res$pvalue[which(res$lhs %in% select)]
    select=c("direct","direct.below","direct.above")
    direct=res$est[which(res$lhs %in% select)]
    lowerd=res$ci.lower[which(res$lhs %in% select)]
    upperd=res$ci.upper[which(res$lhs %in% select)]
    #
    # se=res$se[which(res$lhs %in% select)]
    directp=res$p[which(res$lhs %in% select)]

    df=data.frame(values=values1,indirect,lower,upper,indirectp,direct,lowerd,upperd,directp)
    df=df[c(2,1,3),]
    df[]=round(df,3)
    attr(df,"mod")=mod

    if(is.null(values)) {
        indirect=res$rhs[res$lhs=="indirect"]
        indirect=str_replace(indirect,paste0(mod,".mean"),"W")
        direct=res$rhs[res$lhs=="direct"]
        direct=str_replace(direct,paste0(mod,".mean"),"W")
    } else{
        indirect=res$rhs[res$lhs=="indirect"]
        indirect=str_replace(indirect,paste0(values[1]),"W")
        direct=res$rhs[res$lhs=="direct"]
        direct=str_replace(direct,paste0(values[1]),"W")
    }

    attr(df,"indirect")=indirect
    attr(df,"direct")=direct
    attr(df,"boot.ci.type")=boot.ci.type
    class(df)=c("modmedSummary","data.frame")
    df
}

#'Extract range from a data.frame
#'@param res A data.frame
#'@param mod Name of moderator
extractRange=function(res,mod){

  select=str_detect(res$lhs,"indirect")
  res1=res[select,c(1,3)]
  temp=res1$rhs
  temp
  result=extractNumber(temp)
  result
  if(length(result)>0) {
    values=result
  } else{
    values=res$est[res$label==paste0(mod,".mean")]+c(0,-1,1)*sqrt(res$est[res$label==paste0(mod,".var")])
  }
  values
}


#' extract number from string
#' @param x a string
#' @export
extractNumber=function(x){
  result=c()
  for(i in seq_along(x)){
      temp=x[i]
      temp=str_replace_all(temp,"\\(|\\)","")
      temp=unlist(str_split(temp,"\\+|\\*|-"))
      temp
      select=which(str_detect(temp,"^[0-9|\\.].*"))
      if(length(select)>0) {
          result=c(result,as.numeric(temp[select]))
      }
  }
  result
}

#' Print a string in right alignment
#' @param string A string
#' @param width A numeric
#' @export
rightPrint=function(string,width){
    str_pad(string,width,side="left")
}


#'S3 method print for an object of class modmedSummary
#'@param x An object of class modmedSummary
#'@param ... additional arguments to pass to print.modmedSummary
#'@export
print.modmedSummary=function(x,...){
    count=nrow(x)
    x[]=lapply(x,myformat)

    x[[5]]=pformat(x[[5]])
    x[[9]]=pformat(x[[9]])

    mod=paste0(attr(x,"mod"),"(W)")
    indirect=attr(x,"indirect")
    direct=attr(x,"direct")
    left=max(nchar(mod)+2,8)
    total=73+left

    cat("\nInference for the Conditional Direct and Indirect Effects - boot.ci.type:",attr(x,"boot.ci.type"),"\n")
    cat(paste(rep("=",total),collapse = ""),"\n")
    cat(centerPrint("",left),centerPrint("Indirect Effect",35),centerPrint("Direct Effect",35),"\n")
    cat(centerPrint("",left),centerPrint(indirect,35),centerPrint(direct,35),"\n")
    cat(centerPrint("",left),paste(rep("-",35),collapse = ""),paste(rep("-",36),collapse = ""),"\n")

    cat(centerPrint(mod,left),centerPrint("estimate",8),centerPrint("95% Bootstrap CI",18),centerPrint("p",8))
    cat(centerPrint("estimate",11),centerPrint("95% Bootstrap CI",18),centerPrint("p",8),"\n")
    cat(paste(rep("-",total),collapse = ""),"\n")
    for(i in 1:count){
        cat(rightPrint(x[i,1],left-1),"")
        cat(rightPrint(x[i,2],8))
        cat(paste0(rightPrint(x[i,3],8)," to ",rightPrint(x[i,4],6)))
        cat(rightPrint(x[i,5],8))
        cat(rightPrint(x[i,6],13))
        cat(paste0(rightPrint(x[i,7],8)," to ",rightPrint(x[i,8],6)))
        cat(rightPrint(x[i,9],8),"\n")
    }
    cat(paste(rep("=",total),collapse = ""),"\n")
}


#' Make a table summarizing the moderated mediation
#' @param x An object of class modmedSummary or class lavaan
#' @param vanilla A logical
#' @param ... Further arguments to be passed to modmedSummary
#' @importFrom flextable bg vline add_footer_lines
#' @export
modmedSummaryTable=function(x,vanilla=TRUE,...){

    if("lavaan" %in% class(x)){
       x=modmedSummary(x,...)
    }
    count=nrow(x)
    x[]=lapply(x,myformat)
    x[[5]]=pformat(x[[5]])
    x[[9]]=pformat(x[[9]])

    x1=x

    if(vanilla){
    x1$s=""
    x1$ci=paste0("(",x1$lower," to ",x1$upper,")")
    x1$ci2=paste0("(",x1$lowerd," to ",x1$upperd,")")

    x1=x1[c(1:2,11,5,10,6,12,9)]

    ft=rrtable::df2flextable(x1,vanilla=vanilla,digits=3)
    ft
    hlabel=c(paste0(attr(x,"mod"),"(W)"),"estimate","95% Bootstrap CI","p","","estimate","95% Bootstrap CI","p")
    hlabel
    col_keys=colnames(x1)
    hlabel<-setNames(hlabel,col_keys)
    hlabel=as.list(hlabel)
    hlabel
    ft<-ft %>% set_header_labels(values=hlabel)
    ft
    ft<-ft %>% width(j=c(3,7),width=1.6) %>% width(j=5,width=0.1)
    big_border=fp_border(color="black",width=2)
    hlabel=list(values="",
                indirect=paste0("Indirect Effect\n",attr(x,"indirect")),s="",
                direct=paste0("Direct Effect\n",attr(x,"direct")))
    ft<- ft %>%
        hline_top(part="header",border=fp_border(color="black",width=0)) %>%
        add_header_row(top=TRUE,values=hlabel,colwidths=c(1,3,1,3)) %>%
        hline_top(part="header",border=big_border) %>%
        hline(i=1,j=2:4,part="header",border=fp_border(color="black",width=1))%>%
        hline(i=1,j=6:8,part="header",border=fp_border(color="black",width=1)) %>%
        merge_h_range (i=1,j1=2,j2=4,part="header") %>%
        merge_h_range (i=1,j1=6,j2=8,part="header") %>%
        align(align="center",part="all") %>%
        align(align="right",part="body") %>%
        fontsize(size=12,part="header") %>%
        bold(part="header") %>%
        italic(i=2,j=c(4,8),italic=TRUE,part="header") %>%
        width(j=1,width=1)
    } else{
        x1$ci=paste0("(",x1$lower," to ",x1$upper,")")
        x1$ci2=paste0("(",x1$lowerd," to ",x1$upperd,")")

        x1=x1[c(1:2,10,5,6,11,9)]
        ft=rrtable::df2flextable(x1,vanilla=vanilla,digits=3)

        ft
        hlabel=c(paste0(attr(x,"mod"),"(W)"),"estimate","95% Bootstrap CI","p","estimate","95% Bootstrap CI","p")
        hlabel
        col_keys=colnames(x1)
        hlabel<-setNames(hlabel,col_keys)
        hlabel=as.list(hlabel)
        hlabel
        ft<-ft %>% set_header_labels(values=hlabel)
        ft
        ft<-ft %>% width(j=c(3,6),width=1.6) %>% width(j=5,width=0.1)
        big_border=fp_border(color="black",width=2)
        hlabel=list(values=paste0(attr(x,"mod"),"(W)"),
                    indirect=paste0("Indirect Effect\n",attr(x,"indirect")),
                    direct=paste0("Direct Effect\n",attr(x,"direct")))
        ft<- ft %>%
            hline_top(part="header",border=fp_border(color="black",width=0)) %>%
            add_header_row(top=TRUE,values=hlabel,colwidths=c(1,3,3)) %>%
            hline_top(part="header",border=big_border) %>%
            hline(i=1,j=2:4,part="header",border=fp_border(color="black",width=1))%>%
            hline(i=1,j=5:7,part="header",border=fp_border(color="black",width=1))
        ft<-ft  %>%
            merge_h_range (i=1,j1=2,j2=4,part="header") %>%
            merge_h_range (i=1,j1=5,j2=7,part="header") %>%
            align(align="center",part="all") %>%
            align(align="right",part="body") %>%
            fontsize(size=12,part="header") %>%
            bold(part="header") %>%
            italic(i=2,j=c(4,7),italic=TRUE,part="header")
        ft<-ft %>% color(i=1,j=1:7,color="white",part="header") %>%
            bg(i=1,j=1:7,bg="#5B7778",part="header") %>%
            merge_at(i=1:2,j=1,part="header")
        ft<-ft %>% vline(i=1:2,border=fp_border(color="white"),part="header") %>%
            hline(i=1:2,border=fp_border(color="white"),part="header") %>%
            width(j=1,width=1)
    }

    ft<-ft %>% add_footer_lines(paste0("boot.ci.type = ",attr(x,"boot.ci.type") )) %>%
        align(align="right",part="footer")
    ft
}

#' Summarize the mediation effects
#' @param fit An object of class lavaan
#' @param boot.ci.type Type of bootstrapping interval. Choices are c("norm","basic","perc",bca.simple")
#' @param effects Names of effects to be summarized
#' @importFrom purrr map_df
#' @export
#' @return A data.frame and an object of class medSummary
medSummary=function(fit,boot.ci.type="bca.simple",effects=c("indirect","direct")){
  if(boot.ci.type!="all"){
    res=parameterEstimates(fit,boot.ci.type = boot.ci.type,
                           level = .95, ci = TRUE,
                           standardized = FALSE)
    res
    select=which(str_detect(res$label,"direct|total|prop"))
    res=res[select,c(1,3,5,9,10,8)]
    names(res)[1:2]=c("Effect","equation")
    attr(res,"boot.ci.type")=boot.ci.type
    attr(res,"se")=fit@Options$se
    class(res)=c("medSummary","data.frame")
    res
  } else{
        # effects=c("indirect","direct","total")
    count=length(effects)
    type=c("norm","basic","perc","bca.simple")
    result=list()
    for(i in 1:4){
      res=parameterEstimates(fit,boot.ci.type = type[i],
                             level = .95, ci = TRUE,
                             standardized = FALSE)

      res=res[res$label %in% effects,c(1,3,5,9,10,8)]
      res$type=type[i]
      result[[i]]=res
    }
    df1=purrr::map_df(result,rbind)
    df1
    equation=df1$rhs[1:count]
    equation
    df=list()
    for(i in seq_along(effects)){
        df[[i]]=df1[df1$lhs==effects[i],]
    }
    df
    df=lapply(1:count,function(i){
        df[[i]][3:6]})
    df
    df2=purrr::reduce(df,cbind)
    df2
    temp=c("est","lower","upper","p")
    colnames(df2)=paste0(rep(temp,count),".",rep(effects,each=4))
    df2$type=type
    df2 <- df2 %>% select(type,everything())
    attr(df2,"effects")<-effects
    attr(df2,"equations")<-equation
    attr(df2,"se")=fit@Options$se
    class(df2)=c("medSummary2","data.frame")
    #str(df2)
    df2
  }
}

#'S3 method print for an object of class modmedSummary
#'@param x An object of class medSummary
#'@param ... additional arguments to pass to print.medSummary
#'@export
print.medSummary=function(x,...){
    count=nrow(x)
    x[]=lapply(x,myformat)

    x[[6]]=pformat(x[[6]])
    tempnames=c("Effect","Equation","est","95% Bootstrap CI","p")
    if(attr(x,"se")=="standard") tempnames[4]="95% CI"

    widthEffect=max(nchar(x$Effect))+2
    widthEq=max(nchar(x$equation))+2

    width=c(widthEffect,widthEq,8,19,8)

    total=sum(width)
    cat(centerPrint("Summary of Mediation Effects",total),"\n")
    cat(paste(rep("=",total),collapse = ""),"\n")
    cat("  ")
    for(i in seq_along(tempnames)){
        cat(centerPrint(tempnames[i],width[i]))
    }
    cat("\n")
    cat(paste(rep("-",total),collapse = ""),"\n")
    for(i in 1:nrow(x)){
        cat(centerPrint(x[i,1],width[1]))
        cat(centerPrint(x[i,2],width[2]))
        cat(rightPrint(x[i,3],width[3]))
        cat(rightPrint(paste0("(",x[i,4]," to ",x[i,5],")"),width[4]))
        cat(rightPrint(x[i,6],width[5]))
        cat("\n")
    }
    cat(paste(rep("=",total),collapse = ""),"\n")
    if(attr(x,"se")!="standard") cat(rightPrint(paste0("boot.ci.type: ",attr(x,"boot.ci.type")),total))
    cat("\n")
}

#'S3 method print for an object of class modmedSummary
#'@param x An object of class medSummary
#'@param ... additional arguments to pass to print.medSummary
#'@export
print.medSummary2=function(x,...){
  count=(ncol(x)-1)/4
  count
  df=x
  df[]=lapply(df,myformat)

  for(i in 1:count){
     df[[1+i*4]]=pformat(df[[1+i*4]])
  }
  for(i in 1:count){
    df[[paste0("ci",i)]]=paste0("(",df[[3+(i-1)*4]]," to ",df[[4+(i-1)*4]],")")
  }
  df
  select=c(1)
  for(i in 1:count){
    select=c(select,2+(i-1)*4,count*4+1+i,5+(i-1)*4)
  }
  df=df[select]
  df
  if(attr(x,"se")=="standard") temp=rep(c("estimate","95% CI","p"),count)
  else temp=rep(c("estimate","95% Bootstrap CI","p"),count)
  colnames(df)=c("type",temp)
  width=c(12,rep(c(8,22,8),count))
  colwidth=38
  total=sum(width)
  cat(centerPrint("Summary of Mediation Effects",total),"\n")
  cat(paste(rep("=",total),collapse = ""),"\n")
  cat(centerPrint("",12))
  for(i in 1:count){
     cat(centerPrint(attr(x,"effects")[i],colwidth))
  }
  cat("\n")
  cat(centerPrint("",11))
  for(i in 1:count){
    cat(centerPrint(attr(x,"equations")[i],colwidth))
  }
  cat("\n",centerPrint("",12))
  for(i in 1:count) cat(paste(rep("-",colwidth),collapse = ""))
  cat("\n  ")
  for(i in seq_along(colnames(df))){
    cat(centerPrint(colnames(df)[i],width[i]))
  }
  cat("\n")
  cat(paste(rep("-",total),collapse = ""),"\n")
  for(i in 1:nrow(df)){
    for(j in 1:ncol(df)) {
       cat(centerPrint(df[i,j],width[j]))
    }
    cat("\n")
  }
  cat(paste(rep("=",total),collapse = ""),"\n")
  cat("\n")
}

#' Make a table summarizing the mediation effects
#' @param x An object of class medSummary or medSummary2 or lavaan
#' @param vanilla A logical
#' @param ... Further arguments to be passed to medSummary
#' @export
medSummaryTable=function(x,vanilla=TRUE,...){
   if("lavaan" %in% class(x)){
      x=medSummary(x,...)
   }
   if("medSummary2" %in% class(x)){
     medSummaryTable2(x,vanilla=vanilla)
   } else{
     medSummaryTable1(x,vanilla=vanilla)
   }
}

#' Make a table summarizing the mediation effects
#' @param x An object of class medSummary
#' @param vanilla A logical
#' @importFrom flextable autofit
#' @export
medSummaryTable1=function(x,vanilla=TRUE){
   df=x
   df[]=lapply(df,myformat)
   df[[6]]=pformat(df[[6]])
   df$ci=paste0("(",df$ci.lower," to ",df$ci.upper,")")
   df<-df %>% select(c(1,2,3,7,6))
   colnames(df)[2:5]=c("Equation","estimate","95% Bootstrap CI","p")
   if(attr(x,"se")=="standard") colnames(df)[4]="95% CI"
   table=df2flextable(df,vanilla=vanilla)
   table %>% width(j=4,width=2) %>%
     align(j=c(1,2,4),align="center",part="body") %>%
     fontsize(size=12,part="header") %>%
     bold(part="header") %>%
     italic(i=1,j=c(5),italic=TRUE,part="header")
   if(attr(x,"se")!="standard") {
     table <- table %>%
       add_footer_lines(paste0("boot.ci.type = ",attr(x,"boot.ci.type") )) %>%
       align(align="right",part="footer")
   }
   table %>%
     autofit()

}

#' Make a table summarizing the mediation effects
#' @param x An object of class medSummary2
#' @param vanilla A logical
#' @importFrom flextable autofit
#' @export
medSummaryTable2=function(x,vanilla=TRUE){

  count=(ncol(x)-1)/4
  count
  df=x
  class(df)="data.frame"
  df[]=lapply(df,myformat)

  for(i in 1:count){
    df[[1+i*4]]=pformat(df[[1+i*4]])
  }
  for(i in 1:count){
    df[[paste0("ci",i)]]=paste0("(",df[[3+(i-1)*4]]," to ",df[[4+(i-1)*4]],")")
  }
  if(vanilla){
    for(i in 1:count){ df[[paste0("s",i)]]=""}
    select=c(1)
    for(i in 1:count){
      select=c(select,2+(i-1)*4,count*4+1+i,5+(i-1)*4)
      if(i<count) select=c(select,which(colnames(df)==paste0("s",i)))
    }
    df=df[select]
    df
    if(attr(x,"se")=="standard") temp=rep(c("estimate","95% CI","p",""),count)
    else temp=rep(c("estimate","95% Bootstrap CI","p",""),count)

    temp=c("type",temp[-length(temp)])
    temp
    table=rrtable::df2flextable(df,vanilla=vanilla)
    table
    col_keys=colnames(df)
    hlabel<-setNames(temp,col_keys)
    hlabel=as.list(hlabel)
    hlabel
    table<-table %>% set_header_labels(values=hlabel)

    hlabel=list(type="",
                est.indirect=paste0("Indirect Effect\n",attr(x,"equations")[1]),
                s1="",
                est.direct=paste0("Direct Effect\n",attr(x,"equations")[2]))
    big_border=fp_border(color="black",width=2)

    table<-table %>%
      hline_top(part="header",border=fp_border(color="black",width=0)) %>%
      add_header_row(top=TRUE,values=hlabel,colwidths=c(1,3,1,3)) %>%
      hline_top(part="header",border=big_border) %>%
      hline(i=1,j=6,part="header",border=fp_border(color="black",width=1))%>%
      hline(i=1,j=2,part="header",border=fp_border(color="black",width=1)) %>%
      width(j=c(5),width=0.01)


    table<-table %>%
      align(j=c(1),align="center",part="body") %>%
      align(align="center",part="header") %>%
      fontsize(size=12,part="header") %>%
      bold(part="header") %>%
      italic(i=2,j=c(4,7),italic=TRUE,part="header") %>%
      width(j=c(3,7),width=2) %>%
      align(j=c(3,7),align="center",part="all")
  } else{
    # vanilla=FALSE
    select=c(1)
    for(i in 1:count){
      select=c(select,2+(i-1)*4,count*4+1+i,5+(i-1)*4)
    }
    df=df[select]
    df
    temp=rep(c("estimate","95% Bootstrap CI","p"),count)
    if(attr(x,"se")=="standard") temp[2]="95% CI"
    temp =c("type",temp)
    table=rrtable::df2flextable(df,vanilla=vanilla)
    table
    col_keys=colnames(df)
    hlabel<-setNames(temp,col_keys)
    hlabel=as.list(hlabel)
    hlabel
    table<-table %>% set_header_labels(values=hlabel)
    table
    hlabel=list(type="type",
                est.indirect=paste0("Indirect Effect\n",attr(x,"equations")[1]),
                est.direct=paste0("Direct Effect\n",attr(x,"equations")[2]))
    big_border=fp_border(color="black",width=2)

    table<-table %>%
      add_header_row(top=TRUE,values=hlabel,colwidths=c(1,3,3))


    table<-table %>%
      align(j=c(1),align="center",part="body") %>%
      align(align="center",part="header") %>%
      fontsize(size=12,part="header") %>%
      bold(part="header") %>%
      italic(i=2,j=c(4,7),italic=TRUE,part="header") %>%
      width(j=c(3,6),width=2)

    table<-table %>% color(i=1,j=1:7,color="white",part="header") %>%
      bg(i=1,j=1:7,bg="#5B7778",part="header") %>%
      merge_at(i=1:2,j=1,part="header")
    table
    table<-table %>% vline(i=1:2,border=fp_border(color="white"),part="header") %>%
      hline(i=1:2,border=fp_border(color="white"),part="header") %>%
      width(j=1,width=1) %>%
      align(j=c(3,6),align="center",part="all")
  }
  table
}

